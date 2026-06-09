/*
 * Copyright 2026 Nils Knieling. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * STACKIT Compute Engine Instance Picker
 * One row per instance type + region + availability tier.
 */

/* FILTERS */
const filterParamsNumber = {
	filterOptions: ['equals', 'greaterThan', 'greaterThanOrEqual', 'lessThan', 'lessThanOrEqual'],
	defaultOption: 'greaterThanOrEqual',
	debounceMs: 100,
};
const filterParamsText = {
	filterOptions: ['equals', 'notEqual', 'contains', 'notContains', 'startsWith', 'endsWith'],
	defaultOption: 'contains',
	debounceMs: 100,
};
const filterParamsBoolean = {
	filterOptions: ['equals'],
	defaultOption: 'equals',
	maxNumConditions: 1,
	debounceMs: 0,
};

/* FORMATTERS */
function booleanFormatter(params) {
	return (params.value >= 1) ? '✅' : '❌';
}
function metroFormatter(params) {
	return (params.value >= 1) ? 'Multi-AZ' : 'Single-AZ';
}

/* GRID */
const gridOptions = {
	columnDefs: [
		{
			headerName: 'Instance Type',
			children: [
				{
					headerName: 'Name',
					headerTooltip: 'Instance Type (flavor)',
					field: 'instanceType',
					cellRenderer: params => '<a href="./' + params.value + '.html">' + params.value + '</a>',
					tooltipValueGetter: params => 'STACKIT instance type ' + params.value + ' in region ' + params.data.region,
					pinned: 'left',
					checkboxSelection: true,
					width: 160,
				},
				{
					headerName: 'Family',
					headerTooltip: 'Instance Family',
					field: 'instanceFamily',
					columnGroupShow: 'open',
					width: 110,
				},
				{
					headerName: 'Family Name',
					headerTooltip: 'Instance Family Name',
					field: 'instanceFamilyName',
					columnGroupShow: 'open',
					tooltipField: 'instanceFamilyName',
					width: 200,
				},
			]
		},
		{
			headerName: 'Region',
			children: [
				{
					headerName: 'Code',
					headerTooltip: 'Region Code',
					field: 'region',
					tooltipField: 'regionName',
					width: 100,
				},
				{
					headerName: 'Availability',
					headerTooltip: '0 = Single-AZ, 1 = Multi-AZ (metro)',
					field: 'metro',
					filterParams: filterParamsBoolean,
					valueFormatter: metroFormatter,
					width: 130,
				},
				{
					headerName: 'Name',
					field: 'regionName',
					columnGroupShow: 'open',
					width: 140,
				},
				{
					headerName: 'City',
					field: 'city',
					columnGroupShow: 'open',
					width: 140,
				},
			]
		},
		{
			headerName: 'Processor',
			children: [
				{
					headerName: 'vCPUs',
					headerTooltip: 'vCPUs',
					field: 'vCpu',
					filter: 'agNumberColumnFilter',
					filterParams: filterParamsNumber,
					width: 100,
				},
				{ 
					headerName: 'Frequency',
					field: "cpuBaseClockGhz",
					filter: 'agNumberColumnFilter',
					filterParams: filterParamsNumber,
					headerTooltip: 'CPU base clock frequency',
					width: 120,
					cellClass: 'frequency',
				},
				{
					headerName: 'Arch',
					headerTooltip: 'CPU Architecture',
					field: 'cpuArchitecture',
					columnGroupShow: 'open',
					width: 110,
				},
				{
					headerName: 'CPU Vendor',
					headerTooltip: 'CPU Vendor',
					field: 'cpuVendor',
					columnGroupShow: 'open',
					width: 120,
				},
				{
					headerName: 'CPU Model',
					headerTooltip: 'CPU Model',
					field: 'cpuModel',
					columnGroupShow: 'open',
					width: 180,
				},
				{
					headerName: 'Shared',
					headerTooltip: 'CPU Over-provisioning (shared vCPUs)',
					field: 'cpuOverprovisioning',
					columnGroupShow: 'open',
					filterParams: filterParamsBoolean,
					valueFormatter: booleanFormatter,
					width: 100,
				},
			]
		},
		{
			headerName: 'Memory',
			children: [
				{
					headerName: 'RAM',
					headerTooltip: 'Memory in GB',
					field: 'ramGb',
					cellClass: 'memory',
					filter: 'agNumberColumnFilter',
					filterParams: filterParamsNumber,
					width: 110,
				},
			]
		},
		{
			headerName: 'Storage',
			children: [
				{
					headerName: 'Local Disk',
					headerTooltip: 'Has a local disk',
					field: 'localDisk',
					filterParams: filterParamsBoolean,
					valueFormatter: booleanFormatter,
					width: 110,
				},
				{
					headerName: 'Local Disk GB',
					headerTooltip: 'Local disk size in GB',
					field: 'localDiskGb',
					cellClass: 'disk',
					filter: 'agNumberColumnFilter',
					filterParams: filterParamsNumber,
					columnGroupShow: 'open',
					width: 130,
				},
			]
		},
		{
			headerName: 'GPU',
			children: [
				{
					headerName: 'GPUs',
					headerTooltip: 'Number of GPUs',
					field: 'gpuCount',
					filter: 'agNumberColumnFilter',
					filterParams: filterParamsNumber,
					width: 90,
				},
				{
					headerName: 'GPU Model',
					field: 'gpuModel',
					columnGroupShow: 'open',
					width: 140,
				},
			]
		},
		{
			headerName: 'Price',
			children: [
				{
					headerName: 'per Hour',
					headerTooltip: 'Price per hour (EUR)',
					field: 'priceHour',
					cellClass: 'currency',
					filter: 'agNumberColumnFilter',
					filterParams: filterParamsNumber,
					width: 130,
					sort: 'asc',
				},
				{
					headerName: 'per Month',
					headerTooltip: 'Price per month (EUR)',
					field: 'priceMonth',
					cellClass: 'currency',
					filter: 'agNumberColumnFilter',
					filterParams: filterParamsNumber,
					width: 130,
				},
				{
					headerName: 'SKU',
					field: 'sku',
					columnGroupShow: 'open',
					width: 120,
				},
			]
		},
	],
	// Defaults
	defaultColDef: {
		resizable: true,
		sortable: true,
		minWidth: 90,
		maxWidth: 400,
		//width: 110,
		filter: 'agTextColumnFilter',
		filterParams: filterParamsText,
		floatingFilter: true,
		//editable: true,
	},
	groupHideOpenParents: true,
	tooltipShowDelay: 0,
	debounceVerticalScrollbar: true,
	ensureDomOrder: true,
	suppressColumnVirtualisation: true,
	rowBuffer: 60,
	rowSelection: 'multiple',
	rowMultiSelectWithClick: true,
	//rowDragManaged: true,
	//rowDragMultiRow: true,
	pagination: true,
	paginationPageSize: 50,
	//domLayout: 'autoHeight',
};

/* INIT */
document.addEventListener('DOMContentLoaded', function () {
	const gridDiv = document.querySelector('#myGrid');
	// AG Grid v31+: createGrid() returns the Grid API. gridOptions.api is removed.
	const gridApi = agGrid.createGrid(gridDiv, gridOptions);

	fetch('instances.json')
		.then(response => response.json())
		.then(data => {
			gridApi.setGridOption('rowData', data);

			// Optional ?name=<instanceType> deep link sets a filter
			const params = new URLSearchParams(window.location.search);
			const name = params.get('name');
			if (name) {
				gridApi.setColumnFilterModel('instanceType', {
					filterType: 'text',
					type: 'equals',
					filter: name,
				}).then(() => gridApi.onFilterChanged());
			}
		})
		.catch(err => console.error('Failed to load instances.json', err));
});
