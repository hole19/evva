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
 ```

## The events sheet

 The events sheet is read by column header, so column order does not matter and
 unknown columns are ignored.

 | Column | Required | Meaning |
 | --- | --- | --- |
 | `Event Name` | yes | The event name |
 | `Event Properties` | no | Comma separated `name:Type` pairs |
 | `Event Destination` | no | Comma separated destinations |
 | `Platform` | no | Which platforms track the event |

### Platform

 `Platform` restricts an event to some platforms. Evva only generates the events
 matching the `type` in your `evva_config.yml`.

 Accepted values are `iOS`, `Android`, `both` and `all`, case insensitive, and
 comma separated so an event can list several: `iOS, Android`.

 The header is matched ignoring case and surrounding whitespace, so `platform` and
 `Platform ` are both found.

 An empty cell means every platform, as does a sheet with no `Platform` column at
 all, so sheets that predate this column keep generating exactly what they did
 before. Any other value aborts the run and names the offending event.

 When no `Platform` column is found the run says so, because "every event was
 generated" is otherwise indistinguishable from a header that failed to match:

 ```
 [INFO] No Platform column in the events sheet, every event will be generated for every platform
 ```

 Enums that no longer have a referencing event after filtering are pruned. Enums
 that already had no reference before filtering are left alone.

 People properties have no `Platform` column and are never filtered.
