tableextension 54105 "Ext Sales Header" extends "Sales Header"
{
    fields
    {
        field(54100; "Send Trustpilot Invite"; Boolean)
        {
            Caption = 'Send Trustpilot Invite';
            DataClassification = ToBeClassified;
        }
        // field(54101; "IsInvited"; Boolean)
        // {
        //     Caption = 'IsInvited';
        //     DataClassification = ToBeClassified;
        // }
        field(54103; "IspersonalisationEngraving"; Boolean)
        {
            Caption = 'IspersonalisationEngraving';
            FieldClass = FlowField;
            CalcFormula = Exist("Sales Line" WHERE("Document No." = field("No."), Personalisation = filter('*Engraving*')));
        }
        field(54104; "IsEligibalForTrustpilotReview"; Boolean)
        {
            Caption = 'IsEligibalForTrustpilotReview';
            FieldClass = FlowField;
            CalcFormula = Exist("Sales Line" WHERE("Document No." = field("No."), Description = filter('*Welch Allyn*' | '*Heine*' | '*Keeler*' | '*Riester*' | '*Littmann Stetho*')));
        }
        field(54106; "IsPriceZero"; Decimal)
        {
            Caption = 'IsPriceZero';
            FieldClass = FlowField;
            CalcFormula = max("Sales Line"."Unit Price" WHERE("Document No." = field("No."), "Unit Price" = filter(> 0)));
        }
        field(54107; "CheckedForItem"; Boolean)
        {
            Caption = 'CheckedForItemStartWith-MBC/';
            FieldClass = FlowField;
            CalcFormula = exist("Sales Line" where("Document No." = field("No."), "No." = filter('@MBC/*')));
        }
        field(54108; "SelectForReview"; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = exist("Sales Line" where("Document No." = field("No."), "Select For Review" = filter(true)));
        }
        field(54109; "Surgery Network Header"; Boolean)
        {
            Caption = 'Surgery Network Header';
            DataClassification = CustomerContent;
        }
        field(54110; "Order Batch"; Text[2048])
        {
            Caption = 'Order Batch';
            DataClassification = CustomerContent;
        }
    }
}
