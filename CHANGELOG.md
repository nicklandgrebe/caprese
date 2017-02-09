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

## 0.3.6

* Only allow resource identifiers in request documents to use `id` for primary key (JSON API adherent) (93c90eb)

## 0.3.7

* Completes error source pointer determination to include primary data items and relationship primary data items

## 0.3.8

* Use default value provided in options arg of errors.add before retrieving the value from the record (0ed5a3e)
