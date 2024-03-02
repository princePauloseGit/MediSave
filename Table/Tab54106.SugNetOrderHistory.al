table 54106 SugNetOrderHistory
{
    Caption = 'SugNetOrderHistory';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; Id; Integer)
        {
            Caption = 'Id';
            AutoIncrement = true;
        }
        field(2; OrderId; Code[100])
        {
            Caption = 'OrderId';
        }
        field(5; IsSent; Boolean)
        {
            Caption = 'IsSent';
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
