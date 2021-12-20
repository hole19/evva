Evva
========

[![Status](https://travis-ci.org/hole19/evva.svg?branch=master)](https://travis-ci.org/hole19/evva?branch=master)
[![Gem](https://img.shields.io/gem/v/evva.svg?style=flat)](http://rubygems.org/gems/evva "View this project in Rubygems")

Evva automatically generates code for triggering events based on a Google Sheets specification. It generated code for both iOS (Swift) and Android (Kotlin).

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
 people_file_name: /file/with/people/property/names
 platforms_file_name: /file/with/platforms
 special_enum_file_name: /file/with/special/enum/properties/
 ```
