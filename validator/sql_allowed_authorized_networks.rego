#
# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package templates.gcp.GCPSQLAllowedAuthorizedNetworksConstraintV1

import data.validator.gcp.lib as lib

deny[{
	"msg": message,
	"details": metadata,
}] {
	constraint := input.constraint
	lib.get_constraint_params(constraint, params)

	asset := input.asset
	asset.asset_type == "sqladmin.googleapis.com/Instance"

	check_ssl(params, asset.resource.settings.ipConfiguration) == false

	message := sprintf("%v has networks with SSL settings in violation of policy", [asset.name])
	metadata := {"resource": asset.name}
}

deny[{
	"msg": message,
	"details": metadata,
}] {
	constraint := input.constraint
	lib.get_constraint_params(constraint, params)

	asset := input.asset
	asset.asset_type == "sqladmin.googleapis.com/Instance"

	forbidden := forbidden_networks(params, asset.resource.settings.ipConfiguration)
	count(forbidden) > 0

	message := sprintf("%v has authorized networks that are not allowed: %v", [asset.name, forbidden])
	metadata := {"resource": asset.name}
}

forbidden_networks(params, ipConfiguration) = forbidden {
	allowed_authorized_networks = lib.get_default(params, "authorized_networks", [])

	# Check whether authorizedNetworks field exists, so that
	# we can report violation when this field is not set
	config_auth_networks = lib.get_default(ipConfiguration, "authorizedNetworks", [{"value": "authorized network unspecified"}])

	configured_networks := {network |
		network = config_auth_networks[_].value
	}

	matched_networks := {network |
		network = configured_networks[_]
		allowed_authorized_networks[_] == network
	}

	forbidden := configured_networks - matched_networks
}

check_ssl(params, ipConfiguration) = result {
	lib.has_field(params, "ssl_enabled") == false
	result = true
}

check_ssl(params, ipConfiguration) = result {
	requireSsl := lib.get_default(ipConfiguration, "requireSsl", false)
	result = requireSsl == params.ssl_enabled
}
