table 54107 ShopifyCustomers
{
    Caption = 'Shopify Customers';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; Id; Guid)
        {
            Caption = 'Id';
        }
        field(2; ShopifyCustomerNo; Code[50])
        {
            Caption = 'ShopifyCustomerNo';
        }
        field(3; BCCustomerNo; Code[50])
        {
            Caption = 'BCCustomerNo';
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
