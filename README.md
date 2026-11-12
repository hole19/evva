Evva
========

[![Status](https://travis-ci.org/hole19/evva.svg?branch=master)](https://travis-ci.org/hole19/evva?branch=master)
[![Gem](https://img.shields.io/gem/v/evva.svg?style=flat)](http://rubygems.org/gems/evva "View this project in Rubygems")

Evva automatically generates code for triggering events based on a Google Sheets specification. It generates code for both Swift (iOS) and Kotlin (Android).

# Instalation

` gem install evva `

# Usage
 1. Open the terminal in app project base
 2. Run `evva`
 3. That's it (given that someone already configured Evva)

# Configuration
 Evva's configuration comes from a evva_config.yml file that should be placed on your
 app root directory. The .yml file has the following structure.

 ```
 type: Android|iOS

 data_source:
  type: google_sheet
  events_url: <GOOGLE-DRIVE-EVENTS-SHEET-URL>
  people_properties_url: <GOOGLE-DRIVE-PEOPLE-PROPERTIES-SHEET-URL>
  enum_classes_url: <GOOGLE-DRIVE-ENUM-CLASSES-SHEET-URL>

 out_path: /folder/where/analytics/classes/are
 event_file_name: /file/with/tracking/functions
 event_enum_file_name: /file/with/event/names
 people_file_name: /file/with/people/properties
 people_enum_file_name: /file/with/people/property/names
 destinations_file_name: /file/with/destinations
 special_enum_file_name: /file/with/special/enum/properties/
 swift_public: false  # optional; when true (iOS), generated Swift uses the public access modifier for generated extensions
 filter_by_platforms:  # optional; array of platforms to keep (e.g. [ios])
   - ios
 ```

## The events sheet

 The events sheet is read by column header, so column order does not matter and
 unknown columns are ignored.

 | Column | Required | Meaning |
 | --- | --- | --- |
 | `Event Name` | yes | The event name |
 | `Event Properties` | no | `name:Type` pairs, comma separated or one per line |
 | `Event Destination` | no | Comma separated destinations |
 | `Platform` | no | Which platforms track the event |

### Event Properties

 Properties can be separated by commas, by line breaks inside the cell, or both,
 so a long list can be kept readable with one property per line (Option+Enter
 on Mac, Alt+Enter on Windows):

 ```
 handicap:Double?
 playing_handicap:Int?
 number_of_played_holes:Int
 ```

 Blank lines, trailing commas and spaces around items or around `:` are ignored.

 Multi-line cells need evva 0.12.0 or newer. Older versions read the whole cell as
 a single broken property, so only convert rows once every app generating from
 the sheet has been updated.

### Destinations

 `Event Destination` (and `Property Destination` in the people properties sheet)
 accepts the same separators, and spaces around each destination are ignored.
 A multi-select dropdown works too: Google's CSV export joins its values with a
 plain comma (`mixpanel,braze`), so it reads the same in older evva versions.

### Platform

 `Platform` tags an event with the platforms it belongs to. Filtering is driven
 by the `filter_by_platforms` key in `evva_config.yml`: only events matching one
 of the listed platforms (or unrestricted events) are generated. When the key is
 absent, every event is generated.

 Any value is accepted as a platform name (case insensitive, comma separated).
 An empty cell means the event is unrestricted and will never be filtered out.

 The header is matched ignoring case and surrounding whitespace, so `platform` and
 `Platform ` are both found.

 When no `Platform` column is found the run says so, because "every event was
 generated" is otherwise indistinguishable from a header that failed to match:

 ```
 [INFO] No Platform column in the events sheet, every event will be generated for every platform
 ```

 Enums whose only referencing events were filtered out are pruned, unless a
 people property also references them.

 People properties have no `Platform` column and are never filtered.
