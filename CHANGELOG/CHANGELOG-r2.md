# Changelog OptimalEdgeDiscovery

<!-- TOC:START -->
## Table of Contents
- [r2.1](#r21)
<!-- TOC:END -->

**Please be aware that the project will have frequent updates to the main branch. There are no compatibility guarantees associated with code in any branch, including main, until it has been released. For example, changes may be reverted before a release is published. For the best results, use the latest published release.**

The below sections record the changes for each API version in each release as follows:

* for an alpha release, the delta with respect to the previous release
* for the first release-candidate, all changes since the last public release
* for subsequent release-candidate(s), only the delta to the previous release-candidate
* for a public release, the consolidated changes since the previous public release

# r2.1

## Release Notes

This release candidate contains the definition and documentation of
* optimal-edge-discovery 0.2.0-rc.1

The API definition(s) are based on
* Commonalities r4.3 (0.8.0)
* Identity and Consent Management r4.2 (0.5.0)

## optimal-edge-discovery 0.2.0-rc.1

**optimal-edge-discovery 0.2.0-rc.1 is a release-candidate version of this API.**

Changes documented below are compared to version 0.1.0.

- API definition **with inline documentation**:
  - [View it on ReDoc](https://redocly.github.io/redoc/?url=https://raw.githubusercontent.com/camaraproject/OptimalEdgeDiscovery/r2.1/code/API_definitions/optimal-edge-discovery.yaml&nocors)
  - [View it on Swagger Editor](https://camaraproject.github.io/swagger-ui/?url=https://raw.githubusercontent.com/camaraproject/OptimalEdgeDiscovery/r2.1/code/API_definitions/optimal-edge-discovery.yaml)
  - OpenAPI [YAML spec file](https://github.com/camaraproject/OptimalEdgeDiscovery/blob/r2.1/code/API_definitions/optimal-edge-discovery.yaml)

### Breaking changes

* `status` field in `EdgeCloudZone` renamed to `edgeCloudZoneStatus` to align with the CAMARA Edge Cloud API naming convention by @DLondonoD in https://github.com/camaraproject/OptimalEdgeDiscovery/pull/29
* `EdgeCloudZoneStatus` enum: removed `unknown` value and `default: unknown` — API providers must always return an explicit status (`active` or `inactive`) by @maheshc01 in https://github.com/camaraproject/OptimalEdgeDiscovery/pull/54

### Added

* N/A

### Changed

* Aligned the API with CAMARA Commonalities r4.3 (0.8.0) by @maheshc01 in https://github.com/camaraproject/OptimalEdgeDiscovery/pull/46
  * Common definitions reused via `$ref` into `CAMARA_common.yaml` (`Device`, `DeviceResponse`, `Port`, `XCorrelator`, error responses)
  * Added mandatory `info.description` sections (authorization and authentication, additional error responses, request body strictness, identifying device from access token)
  * Added `maxLength`, `format`, and `pattern` constraints to string fields
* `edgeCloudRegion` and `edgeCloudZoneStatus` are now required fields in the `EdgeCloudZone` response schema by @maheshc01 in https://github.com/camaraproject/OptimalEdgeDiscovery/pull/54
* `edgeCloudZones` array in the POST response is ordered from best to worst suitability for the given device and application profile by @maheshc01 in https://github.com/camaraproject/OptimalEdgeDiscovery/pull/54
* GET /regions: removed inapplicable `404`, `422`, and `429` error responses by @maheshc01 in https://github.com/camaraproject/OptimalEdgeDiscovery/pull/54
* POST /optimal-edge-discovery: corrected operation description to state that `applicationProfileId` is required by @maheshc01 in https://github.com/camaraproject/OptimalEdgeDiscovery/pull/54

### Fixed

* Added missing `x-correlator` response header to `GET /regions` 200 response by @maheshc01 in https://github.com/camaraproject/OptimalEdgeDiscovery/pull/54
* Fixed `info.description` error code reference from `404 NOT_FOUND` to `404 IDENTIFIER_NOT_FOUND` by @maheshc01 in https://github.com/camaraproject/OptimalEdgeDiscovery/pull/54
* Fixed POST 200 response example to use valid UUID values by @maheshc01 in https://github.com/camaraproject/OptimalEdgeDiscovery/pull/54

### Removed

* `unknown` value removed from `EdgeCloudZoneStatus` enum — also listed under Breaking changes by @maheshc01 in https://github.com/camaraproject/OptimalEdgeDiscovery/pull/54

**Full Changelog**: https://github.com/camaraproject/OptimalEdgeDiscovery/compare/r1.2...r2.1

