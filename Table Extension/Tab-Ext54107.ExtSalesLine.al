tableextension 54107 "Ext Sales Line" extends "Sales Line"
{
    fields
    {
        field(54100; "Select For Review"; Boolean)
        {
            Caption = 'Select For Review';
            FieldClass = FlowField;
            CalcFormula = exist(Item where("No." = field("No."), FacebookReview = filter(false), GoogleReview = filter(false)));
        }
        field(54101; "Surgery Network Lines"; Boolean)
        {
            Caption = 'Surgery Network Lines';
            DataClassification = CustomerContent;
        }
        field(54102; "SN Transaction Id"; Integer)
        {
            Caption = 'SN Transaction Id';
            DataClassification = CustomerContent;
        }
    }
}
