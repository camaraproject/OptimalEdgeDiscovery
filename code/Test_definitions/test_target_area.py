"""Offline OpenAPI 3.0 contract regression tests.

Install: python -m pip install PyYAML==6.0.3 openapi-schema-validator==0.9.0 openapi-spec-validator==0.9.0
Run from the repository root: python -m unittest discover -s code/Test_definitions -p 'test_*.py' -v

These validate the published contract, not a running API implementation.
"""

from copy import deepcopy
from pathlib import Path
import unittest

import yaml
from openapi_schema_validator import OAS30Validator
from openapi_spec_validator import validate


SPEC = yaml.safe_load(
    (Path(__file__).resolve().parents[1] / "API_definitions" /
     "optimal-edge-discovery.yaml").read_text(encoding="utf-8")
)
POINT = {"latitude": 38.2466, "longitude": 21.7346}
CIRCLE = {"areaType": "CIRCLE", "center": POINT, "radius": 5000}
POLYGON = {
    "areaType": "POLYGON",
    "boundary": [POINT, {"latitude": 38.3, "longitude": 21.8},
                 {"latitude": 38.2, "longitude": 21.9}],
}
PROFILE = "2fa85f64-5717-4562-b3fc-2c963f66afa0"


def validator(schema):
    # Keep local references resolvable against the complete document.
    return OAS30Validator(dict(schema, components=SPEC["components"]))


class TargetAreaContract(unittest.TestCase):
    def test_openapi_document(self):
        validate(SPEC)

    def assert_area(self, area, valid):
        target = {"area": area}
        request = {"applicationProfileId": PROFILE, "targetAreas": [target]}
        request_schema = SPEC["paths"]["/retrieve-viable-edge-cloud-zones"][
            "post"]["requestBody"]["content"]["application/json"]["schema"]
        # Check both the reusable target and the actual operation request.
        for schema, payload in [
            ({"$ref": "#/components/schemas/TargetArea"}, target),
            (request_schema, request),
        ]:
            errors = list(validator(schema).iter_errors(payload))
            self.assertEqual(not errors, valid, [e.message for e in errors])

    def test_valid_geometry(self):
        for area in [CIRCLE, POLYGON]:
            with self.subTest(area=area["areaType"]):
                self.assert_area(area, True)

    def test_geometry_is_required(self):
        for area, fields in [(CIRCLE, ["center", "radius"]),
                             (POLYGON, ["boundary"])]:
            for field in fields:
                broken = deepcopy(area)
                del broken[field]
                with self.subTest(area=area["areaType"], missing=field):
                    self.assert_area(broken, False)
        for area_type in ["CIRCLE", "POLYGON"]:
            self.assert_area({"areaType": area_type}, False)

    def test_discriminator_matches_geometry(self):
        for area, wrong in [(CIRCLE, "POLYGON"), (POLYGON, "CIRCLE")]:
            broken = dict(area, areaType=wrong)
            self.assert_area(broken, False)
        for area in [CIRCLE, POLYGON]:
            for area_type in ["RECTANGLE", None]:
                self.assert_area(dict(area, areaType=area_type), False)
            self.assert_area({k: v for k, v in area.items()
                              if k != "areaType"}, False)

    def test_existing_geometry_constraints(self):
        invalid = [
            dict(CIRCLE, radius=0), dict(CIRCLE, radius="5000"),
            dict(CIRCLE, center={"latitude": 91, "longitude": 21}),
            dict(CIRCLE, center={"latitude": 38, "longitude": 181}),
            dict(CIRCLE, center={"latitude": 38}),
            dict(POLYGON, boundary=POLYGON["boundary"][:2]),
            dict(POLYGON, boundary=[POINT] * 16),
            dict(POLYGON, boundary=[POINT, POINT, {"latitude": 38}]),
        ]
        for area in invalid:
            with self.subTest(area=area):
                self.assert_area(area, False)
        self.assert_area(None, False)

    def test_additional_properties_remain_allowed(self):
        for area in [CIRCLE, POLYGON]:
            self.assert_area(dict(area, extension="allowed"), True)
        # Extra geometry fields remain allowed; areaType selects one subtype.
        both = dict(CIRCLE, boundary=POLYGON["boundary"])
        self.assert_area(both, True)
        self.assert_area(dict(both, areaType="POLYGON"), True)

    def test_published_planning_examples(self):
        examples = SPEC["components"]["examples"]
        for name, schema_name in [
            ("PreDeploymentPlanningRequest", "PreDeploymentEdgeDiscoveryInfo"),
            ("PreDeploymentPlanningWithNonViableRequest",
             "PreDeploymentEdgeDiscoveryInfo"),
            ("PreDeploymentPlanningResponse", "PreDeploymentEdgeDiscoveryResponse"),
            ("PreDeploymentPlanningWithNonViableResponse",
             "PreDeploymentEdgeDiscoveryResponse"),
        ]:
            with self.subTest(example=name):
                validator({"$ref": "#/components/schemas/" + schema_name}).validate(
                    examples[name]["value"]
                )


if __name__ == "__main__":
    unittest.main()
