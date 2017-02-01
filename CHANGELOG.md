## 0.3.0

* Have children controllers inherit callbacks from their parent
* Have child records without their own serializers inherit their type names from their parent
* Enforce `Caprese::Record` on all records serialized
* Allow editing of meta tag document
* Modify `validates_associated` to propagate nested association errors to the record itself
* Fail with `422 Unprocessable Entity` if any callbacks add an error to a record being persisted or updated
