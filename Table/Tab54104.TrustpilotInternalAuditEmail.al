table 54104 "Trustpilot Audit Email"
{
    Caption = 'Trustpilot Audit Email';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; Id; Guid)
        {
            Caption = 'Id';
        }
        field(2; "Date/Time"; DateTime)
        {
            Caption = 'Date/Time';
        }
        field(3; "Order No"; Code[20])
        {
            Caption = 'Order No';
        }
        field(4; "Despatch Number"; Code[20])
        {
            Caption = 'Despatch Number';
        }
        field(5; Message; Text[2048])
        {
            Caption = 'Message';
        }
        field(6; "Stack Trace"; Text[2048])
        {
            Caption = 'Stack Trace';
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
