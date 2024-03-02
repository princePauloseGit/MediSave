table 54105 SurgeryNetworkSetting
{
    Caption = 'SurgeryNetworkSetting';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; Id; Integer)
        {
            Caption = 'Id';
            AutoIncrement = true;
        }
        field(2; "Access Token"; Text[2048])
        {
            Caption = 'Access Token';
        }
        field(3; "Environment Type"; Enum "Environment Type")
        {
            Caption = 'Environment Type';
        }
        field(4; "API URL"; Text[2048])
        {
            Caption = 'API URL';
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
