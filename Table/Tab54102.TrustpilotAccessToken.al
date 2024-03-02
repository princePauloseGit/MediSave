table 54102 "Trustpilot Access Token"
{
    Caption = 'Trustpilot Access Token';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; Id; Guid)
        {
            Caption = 'Id';
        }
        field(2; "Access Token"; Text[100])
        {
            Caption = 'Access Token';
        }
        field(3; "Created Date"; Date)
        {
            Caption = 'Created Date';
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
