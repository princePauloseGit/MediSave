tableextension 54103 "Ext Sales Line Archive" extends "Sales Line Archive"
{
    fields
    {
        field(54100; "Select For Review"; Boolean)
        {
            Caption = 'Select For Review';
            FieldClass = FlowField;
            CalcFormula = exist(Item where("No." = field("No."), FacebookReview = filter(false), GoogleReview = filter(false)));
        }
    }
}
