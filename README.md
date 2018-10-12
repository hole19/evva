Evva

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
  sheet_id: <GOOGLE-DRIVE-SHEET-ID>

 out_path: /folder/where/analytics/classes/are
 event_file_name: /file/with/tracking/functions
 event_enum_file_name: /file/with/event/names
 people_file_name: /file/with/people/properties
 special_enum_file_name: //file/with/special/enum/properties/
 ```
