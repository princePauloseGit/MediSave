page 54101 "Trustpilot Settings"
{
    ApplicationArea = All;
    Caption = 'Trustpilot Settings';
    PageType = List;
    CardPageId = "Trustpilot Setting";
    SourceTable = "Trustpilot Settings";
    UsageCategory = Administration;
    InsertAllowed = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {
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
        }
    }
    actions
    {
        area(Navigation)
        {
            action("Send Invite To Trustpilot")
            {
                Image = Email;
                trigger OnAction()
                var
                    cdu3MPOReporting: Codeunit "Trustpilot API";
                    rec: Record "Sales Header";
                begin
                    cdu3MPOReporting.Run();
                end;
            }
        }
    }
}
