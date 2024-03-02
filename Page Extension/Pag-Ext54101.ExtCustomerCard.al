pageextension 54101 ExtCustomerCard extends "Customer Card"
{

    layout
    {
        addlast(General)
        {
            field("GMC Checked"; Rec."GMC Checked")
            {
                ApplicationArea = All;
                Caption = 'GMC Checked';
            }
        }
    }
}
