table 54100 "3M POS Reporting Setup"
{
    Caption = '3M POS Reporting Setup';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; Id; Integer)
        {
            Caption = 'Id';
            AutoIncrement = true;
        }
        field(2; "Distributor Prefix"; Code[30])
        {
            Caption = 'Distributor Prefix';
        }
        field(3; "Email Recipients"; Text[2048])
        {
            Caption = 'Email Recipients';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            begin
                ValidateEmail();
            end;
        }
        field(4; "Email Subject"; Text[2048])
        {
            Caption = 'Email Subject';
        }
    }
    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
        key("Email Recipients"; "Email Recipients")
        {
            Unique = true;
        }
    }
    procedure ValidateEmail()
    var
        MailManagement: Codeunit "Mail Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateEmail(Rec, IsHandled, xRec);
        if IsHandled then
            exit;

        if "Email Recipients" = '' then
            exit;
        MailManagement.CheckValidEmailAddresses("Email Recipients");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateEmail(var Customer: Record "3M POS Reporting Setup"; var IsHandled: Boolean; xCustomer: Record "3M POS Reporting Setup")
    begin
    end;
}