table 54103 "Trustpilot Settings"
{
    Caption = 'Trustpilot Settings';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; Id; Integer)
        {
            Caption = 'Id';
            AutoIncrement = true;
        }
        field(2; "Client Id"; Text[100])
        {
            Caption = 'Client Id';
        }
        field(3; "Client Secret"; Text[100])
        {
            Caption = 'Client Secret';
        }
        field(4; Username; Text[100])
        {
            Caption = 'Username';
        }
        field(5; Password; Text[100])
        {
            Caption = 'Password';
            ExtendedDatatype = Masked;
        }
        field(6; "Template Id"; Text[100])
        {
            Caption = 'Template Id';
        }
        field(7; "Business Unit Id"; Text[100])
        {
            Caption = 'Business Unit Id';
        }
        field(8; "Sender Email"; Text[100])
        {
            Caption = 'Sender Email';
            trigger OnValidate()
            begin
                ValidateEmail("Sender Email");
            end;
        }
        field(9; "Sender Name"; Text[100])
        {
            Caption = 'Sender Name';
        }
        field(10; "Replay To Email"; Text[100])
        {
            Caption = 'Replay To Email';
            trigger OnValidate()
            begin
                ValidateEmail("Replay To Email");
            end;
        }
        field(11; "Audit Email Recipient"; Text[100])
        {
            Caption = 'Audit Email Recipient';
            trigger OnValidate()
            begin
                ValidateEmail("Audit Email Recipient");
            end;
        }
        field(12; "Audit Email Cc"; Text[100])
        {
            Caption = 'Audit Email Cc';
            trigger OnValidate()
            begin
                ValidateEmail("Audit Email Cc");
            end;
        }
    }
    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        if Rec.Count <> 0 then begin
            Error('"You are only allowed to enter one entry in the Trustpilot setting."');
        end;
    end;

    procedure ValidateEmail(Email: Text)
    var
        MailManagement: Codeunit "Mail Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateEmail(Rec, IsHandled, xRec);
        if IsHandled then
            exit;

        if (Email = '') then
            exit;
        MailManagement.CheckValidEmailAddresses(Email);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateEmail(var TrustPilot: Record "Trustpilot Settings"; var IsHandled: Boolean; xTrustPilot: Record "Trustpilot Settings")
    begin
    end;
}
