table 54101 "3M PO Reporting"
{
    Caption = '3M PO Reporting';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; Id; Guid)
        {
            Caption = 'Id';
        }
        field(2; "Distributor Prefix"; Code[30])
        {
            Caption = 'Distributor Prefix';
        }
        field(3; "ShipToCustomerNumberIndicator"; Text[2048])
        {
            Caption = 'Ship To Customer Number Indicator';
        }
        field(4; "ShipToCustomerNumberDUNSNumber"; Text[2048])
        {
            Caption = 'Ship To Customer Number or DUNS Number';
        }
        field(5; "Ship To Customer Country"; Code[30])
        {
            Caption = 'Ship To Customer Country';
        }
        field(6; "BillToCustomerNumberIndicator"; Text[2048])
        {
            Caption = 'Bill To Customer Number Indicator';
        }
        field(7; "BillToCustomerNumberDUNSNumber"; Code[30])
        {
            Caption = 'Bill To Customer Number or DUNS Number';
        }
        field(8; "Bill To Name"; Text[2048])
        {
            Caption = 'Bill To Name';
        }
        field(9; "Bill To Address"; Text[2048])
        {
            Caption = 'Bill To Address';
        }
        field(10; "Bill To City"; Text[2048])
        {
            Caption = 'Bill To City';
        }
        field(11; "Bill To State"; Text[2048])
        {
            Caption = 'Bill To State';
        }
        field(12; "Bill To Postal Code"; Code[30])
        {
            Caption = 'Bill To Postal Code';
        }
        field(13; "Bill To Customer Country"; Code[30])
        {
            Caption = 'Bill To Customer Country';
        }
        field(14; "Product Catalog #"; Code[30])
        {
            Caption = 'Product Catalog #';
        }
        field(15; "Product UPC"; Text[2048])
        {
            Caption = 'Product UPC';
        }
        field(16; "Product SKU"; Text[2048])
        {
            Caption = 'Product SKU';
        }
        field(17; "Product Description"; Text[2048])
        {
            Caption = 'Product Description';
        }
        field(18; "Order Date"; Date)
        {
            Caption = 'Order Date';
        }
        field(19; "Invoice Date"; Date)
        {
            Caption = 'Invoice Date';
        }
        field(20; "Invoice Number"; Code[30])
        {
            Caption = 'Invoice Number';
        }
        field(21; "Quantity Shipped/Returned"; Integer)
        {
            Caption = 'Quantity Shipped/Returned';
        }
        field(22; "Unit of Measure"; Text[2048])
        {
            Caption = 'Unit of Measure';
        }
        field(23; "Unit Distributor Cost"; Decimal)
        {
            Caption = 'Unit Distributor Cost';
        }
        field(24; "UnitDistributorCostUnitMeasure"; Decimal)
        {
            Caption = 'Unit Distributor Cost Unit of Measure';
        }
        field(25; "Extended Distributor Cost"; Decimal)
        {
            Caption = 'Extended Distributor Cost';
        }
        field(26; "Unit Selling Price"; Decimal)
        {
            Caption = 'Unit Selling Price';
        }
        field(27; "Extended Selling Price"; Decimal)
        {
            Caption = 'Extended Selling Price';
        }
        field(28; "Unit Protected Selling Price"; Decimal)
        {
            Caption = 'Unit Protected Selling Price';
        }
        field(29; "Customer Type"; Code[30])
        {
            Caption = 'Customer Type';
        }
        field(30; "3M Contract Number"; Code[100])
        {
            Caption = '3M Contract Number';
        }
        field(31; "Contract Cost"; Decimal)
        {
            Caption = 'Contract Cost';
        }
        field(32; "Contract Cost Unit of Measure"; Decimal)
        {
            Caption = 'Contract Cost Unit of Measure';
        }
        field(33; "Unit Rebate Claim"; Text[2048])
        {
            Caption = 'Unit Rebate Claim';
        }
        field(34; "Vendor Claim Number"; Code[30])
        {
            Caption = 'Vendor Claim Number';
        }
        field(35; "Type of Sale"; Code[30])
        {
            Caption = 'Type of Sale';
        }
        field(36; "Ship To Phone Number"; Integer)
        {
            Caption = 'Ship To Phone Number';
        }
        field(37; "Ship to City"; Code[30])
        {
            Caption = 'Ship to City';
        }
        field(38; "Ship to State"; Code[30])
        {
            Caption = 'Ship to State';
        }
        field(39; "Ship to Postal Code"; Code[30])
        {
            Caption = 'Ship to Postal Code';
        }
        field(40; "Extended Rebate Claim"; Text[2048])
        {
            Caption = 'Extended Rebate Claim';
        }
    }
    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
    }
}
