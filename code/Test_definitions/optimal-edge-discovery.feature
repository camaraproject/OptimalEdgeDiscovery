  @optimal_edge_discovery
Feature: CAMARA Optimal Edge Discovery API, v0.2.0-rc.2 - Operations getRegions and discoverOptimalEdge
  # Input to be provided by the implementation to the tester
  #
  # Implementation indications:
  # * apiRoot: API root of the server URL
  # * List of device identifier types which are supported, among: phoneNumber, ipv4Address, ipv6Address.
  #   For this version, CAMARA does not allow the use of networkAccessIdentifier, so it is considered by default as not supported.
  #
  # Testing assets:
  # * A device object which location is known by the network when connected.
  # * A device object identifying a device for which the service is not applicable, if any.
  # * An applicationProfileId identifying an existing application profile.
  # * An edgeCloudRegion in which Edge Cloud Zones are available.
  #
  # References to OAS spec schemas refer to schemas specified in optimal-edge-discovery.yaml

  Background: Common Optimal Edge Discovery setup
    Given an environment at "apiRoot"
    And the resource "/optimal-edge-discovery/v0.2rc2" as base-url
    And the header "Content-Type" is set to "application/json"
    And the header "Authorization" is set to a valid access token
    And the header "x-correlator" complies with the schema at "#/components/schemas/XCorrelator"
    And the request body is set by default to a request body compliant with the schema at "#/components/schemas/OptimalEdgeDiscoveryInfo"

  # Success scenarios

  @optimal_edge_discovery_getRegions_01_success
  Scenario: Get all available Edge Cloud Regions
    When the request "getRegions" is sent
    Then the response status code is 200
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response body is an array of at most 20 elements, each complying with the OAS schema at "#/components/schemas/EdgeCloudRegion"

  @optimal_edge_discovery_discoverOptimalEdge_01_success
  Scenario: Discover the optimal Edge Cloud Zones for a device and application profile
    Given a valid testing device supported by the service, identified by the token or provided in the request body
    And the request body property "$.applicationProfileId" is set to a value identifying an existing application profile
    When the request "discoverOptimalEdge" is sent
    Then the response status code is 200
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "#/components/schemas/EdgeDiscoveryResponse"
    And the response property "$.edgeCloudZones" contains at least one element, each complying with the OAS schema at "#/components/schemas/EdgeCloudZone"

  @optimal_edge_discovery_discoverOptimalEdge_02_ordered_zones
  Scenario: Edge Cloud Zones are ordered from best to worst suitability
    Given a valid testing device supported by the service, identified by the token or provided in the request body
    And the request body property "$.applicationProfileId" is set to a value identifying an application profile whose requirements are met by more than one Edge Cloud Zone
    When the request "discoverOptimalEdge" is sent
    Then the response status code is 200
    And the response body complies with the OAS schema at "#/components/schemas/EdgeDiscoveryResponse"
    And the response property "$.edgeCloudZones" contains more than one element
    And the response property "$.edgeCloudZones" is ordered from best to worst suitability for the testing device and application profile

  @optimal_edge_discovery_discoverOptimalEdge_03_region_filter
  Scenario: Discover Edge Cloud Zones within a given region
    Given a valid testing device supported by the service, identified by the token or provided in the request body
    And the request body property "$.applicationProfileId" is set to a value identifying an existing application profile
    And the request body property "$.edgeCloudRegion" is set to a region in which Edge Cloud Zones are available
    When the request "discoverOptimalEdge" is sent
    Then the response status code is 200
    And the response body complies with the OAS schema at "#/components/schemas/EdgeDiscoveryResponse"
    And each element of the response property "$.edgeCloudZones" has "edgeCloudRegion" with same value as the request property "$.edgeCloudRegion"

  @optimal_edge_discovery_discoverOptimalEdge_04_multiple_device_identifiers
  Scenario: Device identifier echoed in response when using a 2-legged access token with multiple identifiers
    Given the header "Authorization" is set to a valid 2-legged access token which does not identify a single device
    And at least 2 types of device identifiers are supported by the implementation
    And the request body property "$.device" includes multiple valid device identifiers
    And the request body property "$.applicationProfileId" is set to a value identifying an existing application profile
    When the request "discoverOptimalEdge" is sent
    Then the response status code is 200
    And the response body complies with the OAS schema at "#/components/schemas/EdgeDiscoveryResponse"
    And the response property "$.device" exists
    And the response property "$.device" complies with the OAS schema at "#/components/schemas/DeviceResponse"
    And the response property "$.device" contains a single device identifier that was included in the request

  # Error scenarios for management of input parameter device

  @optimal_edge_discovery_C01.01_device_empty
  Scenario: The device value is an empty object
    Given the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "$.device" is set to: {}
    When the request "discoverOptimalEdge" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  @optimal_edge_discovery_C01.02_device_identifiers_not_schema_compliant
  Scenario Outline: Some device identifier value does not comply with the schema
    Given the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "<device_identifier>" does not comply with the OAS schema at "<oas_spec_schema>"
    When the request "discoverOptimalEdge" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

    Examples:
      | device_identifier                | oas_spec_schema                              |
      | $.device.phoneNumber             | #/components/schemas/PhoneNumber             |
      | $.device.ipv4Address             | #/components/schemas/DeviceIpv4Address       |
      | $.device.ipv6Address             | #/components/schemas/DeviceIpv6Address       |
      | $.device.networkAccessIdentifier | #/components/schemas/NetworkAccessIdentifier |

  # This scenario may happen e.g. with 2-legged access tokens, which do not identify a single device.
  @optimal_edge_discovery_C01.03_device_not_found
  Scenario: Some identifier cannot be matched to a device
    Given the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "$.device" is compliant with the schema but does not identify a valid device
    When the request "discoverOptimalEdge" is sent
    Then the response status code is 404
    And the response property "$.status" is 404
    And the response property "$.code" is "IDENTIFIER_NOT_FOUND"
    And the response property "$.message" contains a user friendly text

  @optimal_edge_discovery_C01.04_unnecessary_device
  Scenario: Device not to be included when it can be deduced from the access token
    Given the header "Authorization" is set to a valid access token identifying a device
    And the request body property "$.device" is set to a valid device
    When the request "discoverOptimalEdge" is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "UNNECESSARY_IDENTIFIER"
    And the response property "$.message" contains a user-friendly text

  @optimal_edge_discovery_C01.05_missing_device
  Scenario: Device not included and cannot be deduced from the access token
    Given the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "$.device" is not included
    When the request "discoverOptimalEdge" is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "MISSING_IDENTIFIER"
    And the response property "$.message" contains a user-friendly text

  @optimal_edge_discovery_C01.06_unsupported_device
  Scenario: None of the provided device identifiers is supported by the implementation
    Given that some types of device identifiers are not supported by the implementation
    And the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "$.device" only includes device identifiers not supported by the implementation
    When the request "discoverOptimalEdge" is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "UNSUPPORTED_IDENTIFIER"
    And the response property "$.message" contains a user-friendly text

  # When the service is only offered to certain types of devices or subscriptions, e.g. IoT, B2C, etc.
  @optimal_edge_discovery_C01.07_device_not_supported
  Scenario: Service not available for the device
    Given that the service is not available for all devices commercialized by the operator
    And a valid device, identified by the token or provided in the request body, for which the service is not applicable
    When the request "discoverOptimalEdge" is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "SERVICE_NOT_APPLICABLE"
    And the response property "$.message" contains a user-friendly text

  # Error code 400

  @optimal_edge_discovery_400.1_no_request_body
  Scenario: Missing request body
    Given the request body is not included
    When the request "discoverOptimalEdge" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  @optimal_edge_discovery_400.2_empty_request_body
  Scenario: Empty object as request body
    Given the request body is set to "{}"
    When the request "discoverOptimalEdge" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  @optimal_edge_discovery_400.3_required_input_properties_missing
  Scenario: Required input property applicationProfileId is missing
    Given a valid testing device supported by the service, identified by the token or provided in the request body
    And the request body property "$.applicationProfileId" is not included
    When the request "discoverOptimalEdge" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  @optimal_edge_discovery_400.4_other_input_properties_schema_not_compliant
  # Test other input properties in addition to device
  Scenario Outline: Input property values do not comply with the schema
    Given the request body property "<input_property>" does not comply with the OAS schema at "<oas_spec_schema>"
    When the request "discoverOptimalEdge" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

    Examples:
      | input_property         | oas_spec_schema                           |
      | $.applicationProfileId | #/components/schemas/ApplicationProfileId |
      | $.edgeCloudRegion      | #/components/schemas/EdgeCloudRegion      |

  @optimal_edge_discovery_400.5_invalid_x-correlator
  Scenario Outline: Invalid x-correlator value
    Given the header "x-correlator" does not comply with the OAS schema at "#/components/schemas/XCorrelator"
    When the request "<operationId>" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

    Examples:
      | operationId         |
      | getRegions          |
      | discoverOptimalEdge |

  # Error code 401

  @optimal_edge_discovery_401.1_no_authorization_header
  Scenario Outline: No Authorization header
    Given the header "Authorization" is removed
    When the request "<operationId>" is sent
    Then the response status code is 401
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

    Examples:
      | operationId         |
      | getRegions          |
      | discoverOptimalEdge |

  @optimal_edge_discovery_401.2_expired_access_token
  Scenario Outline: Expired access token
    Given the header "Authorization" is set to an expired access token
    When the request "<operationId>" is sent
    Then the response status code is 401
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

    Examples:
      | operationId         |
      | getRegions          |
      | discoverOptimalEdge |

  @optimal_edge_discovery_401.3_invalid_access_token
  Scenario Outline: Invalid access token
    Given the header "Authorization" is set to an invalid access token
    When the request "<operationId>" is sent
    Then the response status code is 401
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

    Examples:
      | operationId         |
      | getRegions          |
      | discoverOptimalEdge |

  # Error code 403

  @optimal_edge_discovery_403_missing_scope
  Scenario Outline: Missing scope in the access token
    Given the header "Authorization" is set to an access token without the required scope "<scope>"
    When the request "<operationId>" is sent
    Then the response status code is 403
    And the response property "$.status" is 403
    And the response property "$.code" is "PERMISSION_DENIED"
    And the response property "$.message" contains a user friendly text

    Examples:
      | operationId         | scope                                  |
      | getRegions          | optimal-edge-discovery:regions:read    |
      | discoverOptimalEdge | optimal-edge-discovery:edge-zones:read |

  # Error code 404

  @optimal_edge_discovery_404.1_no_edge_cloud_zone_found
  Scenario: No Edge Cloud Zone matches the request
    Given a valid testing device supported by the service, identified by the token or provided in the request body
    And the request body property "$.applicationProfileId" is set to a value identifying an existing application profile
    And the request body property "$.edgeCloudRegion" is set to a region in which no Edge Cloud Zone meets the application profile requirements
    When the request "discoverOptimalEdge" is sent
    Then the response status code is 404
    And the response property "$.status" is 404
    And the response property "$.code" is "NOT_FOUND"
    And the response property "$.message" contains a user friendly text
