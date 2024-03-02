page 54102 "Trustpilot Setting"
{
    ApplicationArea = All;
    Caption = 'Trustpilot';
    PageType = StandardDialog;
    SourceTable = "Trustpilot Settings";
    DataCaptionExpression = 'Setting';

    layout
    {
        area(content)
        {
            group("API Details")
            {
                Caption = 'API Details';

                field("Client Id"; Rec."Client Id")
                {
                    ToolTip = 'Specifies the value of the API Key field.';
                    ShowMandatory = true;
                }
                field("Client Secret"; Rec."Client Secret")
                {
                    ToolTip = 'Specifies the value of the API Secret field.';
                    ShowMandatory = true;
                }
                field(Username; Rec.Username)
                {
                    ToolTip = 'Specifies the value of the Username field.';
                    ShowMandatory = true;
                }
                field(Password; Rec.Password)
                {
                    ToolTip = 'Specifies the value of the Password field.';
                    ExtendedDatatype = Masked;
                    ShowMandatory = true;
                }
            }
            group("Setting Details")
            {
                field("Business Unit Id"; Rec."Business Unit Id")
                {
                    ToolTip = 'Specifies the value of the Business Unit Id field.';
                }
                field("Template Id"; Rec."Template Id")
                {
                    ToolTip = 'Specifies the value of the Template Id field.';
                }
                field("Sender Name"; Rec."Sender Name")
                {
                    ToolTip = 'Specifies the value of the Sender Name field.';
                }
                field("Sender Email"; Rec."Sender Email")
                {
                    ToolTip = 'Specifies the value of the Sender Email field.';
                }
                field("Replay To Email"; Rec."Replay To Email")
                {
                    ToolTip = 'Specifies the value of the Replay To Email field.';
                }
            }
            group("Audit Email Details")
            {
                field("Audit Email Recipient"; Rec."Audit Email Recipient")
                {
                    ToolTip = 'Specifies the value of the Audit Email Recipient field.';
                }
                field("Audit Email Cc"; Rec."Audit Email Cc")
                {
                    ToolTip = 'Specifies the value of the Audit Email Cc field.';
                }
            }
        }
    }
}
