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

* Use default value provided in `options` arg of errors.add before retrieving the value from the record (0ed5a3e)

## 0.3.8.1

* Use default value provided in `t` of `options` arg of errors.add before determining by other means (f3ad88e)

## 0.3.8.2

* Fix rendering of nested relationship base errors (17dc96f)

## 0.3.8.4

* Fix `persist_collection_relationships` to not include `through` relationships

## 0.3.9

* Add relationship not_found errors to record instead of throwing parameter error (f4b7415)

## 0.3.10

* Propagate translation options on nested error to parent when validates_associated (2178fbd)

## 0.3.11

* Allow `record_scope` and `relationship_scope` to return `[]`

## 0.3.12

* Refactor RecordNotFoundError and AssociationNotFoundError to use separate `parameter` translations

## 0.3.13

* Fix bug where `queried_record` uses primary key other than `:id`

## 0.3.14

* Add `caprese_is_attribute?` attribute aliasing helper

## 0.3.15

* Remove dependency on `ActiveRecord#assign_attributes`

## 0.3.15.1

* Allow calling of `assign_attributes` if the record `responds_to` it

## 0.3.16

* Only use `Caprese::Record::AssociatedValidator` if `caprese_style_errors`

## 0.3.17

* Update rendering concern serializer_for to resemble Serializer.serializer_for

## 0.3.18

* Allow serialized data links to use parent class links

## 0.3.19

* Set `::Record.caprese_style_errors` to false when rendering errors, because around_action is not finalized

## 0.3.19.1

* Rescue `Exception` temporarily, so we can always turn off `caprese_style_errors`

## 0.3.19.2

* Fix rendering of non-JSON actions

## 0.3.19.3

* Fix use of `ActiveRecord::Validations::AssociatedValidator` in `Caprese::AssociatedValidator`

## 0.3.20

* Add `Caprese::Controller#resource_type_aliases` method that returns object mapping type aliases to actual types for the application
* Add `Caprese::Record.caprese_field_aliases` method that returns object mapping field aliases to actual fields for the record
* Add `Caprese::Record.caprese_type` method that returns singular symbol indicating the type to use when serializing the record. (`Caprese::Serializer.json_api_key` now uses this.)

## 0.3.21

* Change `::Record.caprese_style_errors` to false by default so non-Caprese errors render normally

## 0.3.22

* Add query_params fields and include to relationship endpoints

## 0.3.23

* Require AMS 0.10.5

## 0.3.23.1

* Actually require AMS 0.10.5 (lol)

## 0.3.24

* Add `Caprese.config.isolated_namespace` to enable Caprese to work with isolate_namespace Engines by trimming the `isolated_namespace` off the front of the result of calls to `version_module`, `version_path`, `version_name`, etc.

## 0.3.25

* Add `namespaced_module` and `unnamespace` helper to Versioning that provides full module namespace when `config.isolate_namespace` is present (replaces the old functionality of `version_module` and `unversion`)

## 0.3.26

* Record the field aliases that are used in the request so responses will use the same aliases
* Allow options like `serializer` to be passed into `Serializer` association definitions
* Allow specification of `relationship_serializer(name)` for serializing `get_relationship_data`, similar to `relationship_scope`
* Fix bug that crashes when `[relationship]/data` is missing
* Fix bug in `#update_relationship_definition`

## 0.3.27

* Fix bug in JSON API adapter that inappropriately aliases relationships

## 0.4.0

* Modifies behavior of `config.optimize_relationships`
  * Original behavior: Only sends `links` of relationships (no `data`) except those that are in `includes`
  * New behavior: Relationship is omitted from response entirely except those that are in `includes`
* **Breaking:** Modifies behavior of serializer relationships
  * Original behavior: Use the serializer corresponding to the class of objects for the relationships
    * Example: `has_many :productos => ProductSerializer`
  * New behavior: Relationships in serializers use the name of the relationship as an assumption about the serializer for that relationship
    * Example: `has_many :productos => ProductoSerializer`
  * Can override by passing any serializer: `has_many :productos, serializer: ProductSerializer`
  
## 0.4.1

* Allows `:self` link to be overridden in serializers that subclass Caprese::Serializer

## 0.5.0

* Add `relationship_scope(relationship_name, scope) => scope` method for all relationships in serializers, allowing override for custom scoping
* Refactor `assign_record_attributes` to `assign_changes_from_document`, which splits into multiple modular methods that handle relationship data errors with more source pointer detail
  * Adds `ResourceDocumentInvalidError` for errors pertaining to the document instead of record assignment (`RecordInvalidError`)
  * Allows `PATCH` requests to primary endpoints that update autosaving collection relationships  to propagate the nested errors on attributes/relationships up to the primary data so error source pointers are just as detailed as they would be under `POST` requests already
  * Fields are now assigned in a specific order: attributes, singular relationships, collection relationships
* Fix issue regarding `:base` field titles interpolated into error messages
* Add more detailed error responses to `update_relationship_definition` endpoints

## 0.6.0

* Accept and respond with `Content-Type: application/vnd.api+json`

# Master

* Switches to Rails 5, drops support for Rails 4
* Protects against arrays being sent as data for create and update actions
* Allow options to be passed into caprese_resources
