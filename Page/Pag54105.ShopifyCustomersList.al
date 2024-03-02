page 54105 ShopifyCustomersList
{
    ApplicationArea = All;
    Caption = 'Shopify Customers List';
    PageType = List;
    SourceTable = ShopifyCustomers;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(Id; Rec.Id)
                {
                }
                field(BCCustomerNo; Rec.BCCustomerNo)
                {
                }
                field(ShopifyCustomerNo; Rec.ShopifyCustomerNo)
                {
                }
            }
        }
    }
}
