pageextension 54100 ExtSalesOrderCard extends "Sales Order"
{
    layout
    {
        addlast(General)
        {
            field("Send Trustpilot Invite"; Rec."Send Trustpilot Invite")
            {
                ApplicationArea = All;
                Caption = 'Send Trustpilot Invite';
            }
            field("Order Batch"; Rec."Order Batch")
            {
                ApplicationArea = All;
            }
        }
    }
}
