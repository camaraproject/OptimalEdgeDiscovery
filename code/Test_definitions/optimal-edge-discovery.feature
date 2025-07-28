  @Optimal_Edge_Discovery
Feature: CAMARA Optimal Edge Discovery API, v0.1.0-rc.1 - Operations for discovering optimal edge cloud zones

# Input to be provided by the implementation to the tests
# References to OAS spec schemas refer to schemas specified in optimal-edge-discovery.yaml

  Background: Common Optimal Edge Discovery setup
    Given the resource "{apiroot}/optimal-edge-discovery/v0.1rc1" as base-url
    And the header "Content-Type" is set to "application/json"
    And the header "Authorization" is set to a valid access token
    And the header "x-correlator" is set to a UUID value

######### Happy Path Scenarios #################################

  @optimal_edge_discovery_01_get_regions
  Scenario: Get all available Edge Cloud Regions successfully
    When the request "getRegions" is sent
    Then the response code is 200
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response body is an array of EdgeCloudRegion objects
    And each item in the response array complies with the OAS schema at "/components/schemas/EdgeCloudRegion"

  @optimal_edge_discovery_02_discover_optimal_edge
  Scenario: Discover optimal Edge Cloud Zone successfully
    Given a valid device identifier in the system
    And a valid applicationProfileId is provided
    When the request "discoverOptimalEdge" is sent with the device and applicationProfileId
    Then the response code is 200
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "/components/schemas/EdgeDiscoveryResponse"
    And the response contains at least one optimal Edge Cloud Zone

  @optimal_edge_discovery_03_discover_edge_with_filters
  Scenario: Discover Edge Cloud Zone with filter parameters
    Given a valid device identifier in the system
    And a valid applicationProfileId is provided
    And valid filter parameters for edge discovery
    When the request "discoverOptimalEdge" is sent with the device, applicationProfileId and filters
    Then the response code is 200
    And the response header "Content-Type" is "application/json"
    And the response body complies with the OAS schema at "/components/schemas/EdgeDiscoveryResponse"
    And the response contains filtered Edge Cloud Zones matching the specified parameters

######### Error Scenarios #################################

  @optimal_edge_discovery_04_discover_edge_no_results
  Scenario: Discover Edge Cloud Zone with no matching results
    Given a valid device identifier in the system
    And a valid applicationProfileId is provided
    And filter parameters that would return no matching Edge Cloud Zones
    When the request "discoverOptimalEdge" is sent with the device, applicationProfileId and filters
    Then the response code is 404
    And the response header "Content-Type" is "application/json"
    And the response body complies with the OAS schema at "/components/schemas/ErrorInfo"
    And the response property "$.code" is "NOT_FOUND"

  @optimal_edge_discovery_05_get_regions_unauthenticated
  Scenario: Get regions without authentication
    Given the header "Authorization" is not present
    When the request "getRegions" is sent
    Then the response code is 401
    And the response header "Content-Type" is "application/json"
    And the response body complies with the OAS schema at "/components/schemas/ErrorInfo"
    And the response property "$.code" is "UNAUTHENTICATED"

  @optimal_edge_discovery_06_invalid_device_identifier
  Scenario: Discover optimal Edge Cloud Zone with invalid device identifier
    Given an invalid device identifier
    And a valid applicationProfileId is provided
    When the request "discoverOptimalEdge" is sent
    Then the response code is 400
    And the response header "Content-Type" is "application/json"
    And the response body complies with the OAS schema at "/components/schemas/ErrorInfo"
    And the response property "$.code" is "INVALID_ARGUMENT"

  @optimal_edge_discovery_07_device_not_found
  Scenario: Discover optimal Edge Cloud Zone with non-existing device
    Given a non-existing device identifier
    And a valid applicationProfileId is provided
    When the request "discoverOptimalEdge" is sent
    Then the response code is 404
    And the response header "Content-Type" is "application/json"
    And the response body complies with the OAS schema at "/components/schemas/ErrorInfo"
    And the response property "$.code" is "IDENTIFIER_NOT_FOUND"

  @optimal_edge_discovery_08_invalid_filter
  Scenario: Discover optimal Edge Cloud Zone with invalid filter parameters
    Given a valid device identifier in the system
    And a valid applicationProfileId is provided
    And invalid filter parameters
    When the request "discoverOptimalEdge" is sent
    Then the response code is 400
    And the response header "Content-Type" is "application/json"
    And the response body complies with the OAS schema at "/components/schemas/ErrorInfo"
    And the response property "$.code" is "INVALID_ARGUMENT"

  @optimal_edge_discovery_09_unauthenticated
  Scenario: Discover optimal Edge Cloud Zone without authentication
    Given a valid device identifier in the system
    And the header "Authorization" is not present
    When the request "discoverOptimalEdge" is sent
    Then the response code is 401
    And the response header "Content-Type" is "application/json"
    And the response body complies with the OAS schema at "/components/schemas/ErrorInfo"
    And the response property "$.code" is "UNAUTHENTICATED"
