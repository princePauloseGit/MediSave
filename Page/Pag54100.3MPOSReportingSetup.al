page 54100 "3M POS Reporting Setup"
{
    ApplicationArea = All;
    Caption = '3M POS Reporting Setup';
    PageType = List;
    SourceTable = "3M POS Reporting Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Distributor Prefix"; Rec."Distributor Prefix")
                {
                    Caption = 'Distributor Prefix';
                }
                field("Email Recipients"; Rec."Email Recipients")
                {
                    ExtendedDatatype = EMail;
                    Importance = Promoted;
                    ToolTip = 'Specifies the report recipient''s email address.';
                }
                field("Email Subject"; Rec."Email Subject")
                {
                    ToolTip = 'Specifies the 3M POS Report Email Subject';
                }
            }
        }
    }
    actions
    {
        area(Navigation)
        {
            action("Send Email")
            {
                trigger OnAction()
                var
                    cdu3MPOReporting: Codeunit "3M POS Reporting";
                begin
                    cdu3MPOReporting.Run();
                end;
            }
        }
    }
}