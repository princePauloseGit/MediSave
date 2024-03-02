page 54104 "Surgery Network Setting"
{
    ApplicationArea = All;
    Caption = 'Surgery Network';
    PageType = StandardDialog;
    SourceTable = SurgeryNetworkSetting;
    DataCaptionExpression = 'Setting';

    layout
    {
        area(content)
        {
            group(General)
            {
                field("Environment Type"; Rec."Environment Type")
                {
                    ToolTip = 'Specifies the value of the Environment Type field.';
                    ShowMandatory = true;
                }
                field("Access Token"; Rec."Access Token")
                {
                    ToolTip = 'Specifies the value of the Access Token field.';
                    ShowMandatory = true;
                }
                field("API URL"; Rec."API URL")
                {

                }
            }
        }
    }
}