## 0.3.0

* Have children controllers inherit callbacks from their parent
* Have child records without their own serializers inherit their type names from their parent
* Enforce `Caprese::Record` on all records serialized
* Allow editing of meta tag document
* Modify `validates_associated` to propagate nested association errors to the record itself
* Fail with `422 Unprocessable Entity` if any callbacks add an error to a record being persisted or updated

## 0.3.1

* Remove strict dependencies

## 0.3.2

* Allow scoping of `has_many` relationships in serializers, i.e. when the relationship is included in another primary document

## 0.3.3

* Depend on all route primary key URL params to be named `:id`, rather than `Caprese.config.resource_primary_key`

## 0.3.4

* Fix bug in processing of collection relationship data (5e21582)
* Fix bug in persisting of collection relationship data on create (1eb4720)

## 0.3.5

* Ensure that `record_scope` is always provided a symbol as an argument (c61ac0d)
