report 54100 "3M POS Reporting"
{
    ApplicationArea = All;
    Caption = '3M POS Reporting';
    DefaultLayout = Excel;
    ExcelLayout = 'Report Layout/3M POS Reporting.xlsx';
    dataset
    {
        dataitem("3M PO Reporting"; "3M PO Reporting")
        {
            column("DistributorPrefix"; "Distributor Prefix")
            {
            }
            column(ShipToCustomerNumberIndicator; ShipToCustomerNumberIndicator)
            {
            }
            column(ShipToCustomerNumberDUNSNumber; ShipToCustomerNumberDUNSNumber)
            {
            }
            column(ShipToCustomerCountry; "Ship To Customer Country")
            {
            }
            column(BillToCustomerNumberIndicator; BillToCustomerNumberIndicator)
            {
            }
            column(BillToCustomerNumberDUNSNumber; BillToCustomerNumberDUNSNumber)
            {
            }
            column(BillToName; "Bill To Name")
            {
            }
            column(BillToAddress; "Bill To Address")
            {
            }
            column(BillToCity; "Bill To City")
            {
            }
            column(BillToState; "Bill To State")
            {
            }
            column(BillToPostalCode; "Bill To Postal Code")
            {
            }
            column(BillToCustomerCountry; "Bill To Customer Country")
            {
            }
            column(ProductCatalog; "Product Catalog #")
            {
            }
            column(ProductUPC; "Product UPC")
            {
            }
            column(ProductSKU; "Product SKU")
            {
            }
            column(ProductDescription; "Product Description")
            {
            }
            column(OrderDate; "Order Date")
            {
            }
            column(InvoiceDate; "Invoice Date")
            {
            }
            column(InvoiceNumber; "Invoice Number")
            {
            }
            column(QuantityShippedReturned; "Quantity Shipped/Returned")
            {
            }
            column(UnitofMeasure; "Unit of Measure")
            {
            }
            column(UnitDistributorCost; "Unit Distributor Cost")
            {
            }
            column(UnitDistributorCostUnitMeasure; UnitDistributorCostUnitMeasure)
            {
            }
            column(ExtendedDistributorCost; "Extended Distributor Cost")
            {
            }
            column(UnitSellingPrice; "Unit Selling Price")
            {
            }
            column(ExtendedSellingPrice; "Extended Selling Price")
            {
            }
            column(UnitProtectedSellingPrice; "Unit Protected Selling Price")
            {
            }
            column(CustomerType; "Customer Type")
            {
            }
            column("ThreeMonthContractNumber"; "3M Contract Number")
            {
            }
            column(ContractCost; "Contract Cost")
            {
            }
            column(ContractCostUnitofMeasure; "Contract Cost Unit of Measure")
            {
            }
            column(UnitRebateClaim; "Unit Rebate Claim")
            {
            }
            column(ExtendedRebateClaim; "Extended Rebate Claim")
            {
            }
            column(VendorClaimNumber; "Vendor Claim Number")
            {
            }
            column(TypeofSale; "Type of Sale")
            {
            }
            column(ShipToPhoneNumber; "Ship To Phone Number")
            {
            }
            column(ShiptoCity; "Ship to City")
            {
            }
            column(ShiptoState; "Ship to State")
            {
            }
            column(ShiptoPostalCode; "Ship to Postal Code")
            {
            }
        }
    }
    requestpage
    {
        layout
        {
            area(content)
            {
                group(GroupName)
                {
                }
            }
        }
        actions
        {
            area(processing)
            {
            }
        }
    }
}