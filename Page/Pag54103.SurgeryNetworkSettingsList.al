page 54103 "Surgery Network Settings"
{
    ApplicationArea = All;
    Caption = 'Surgery Network';
    PageType = List;
    SourceTable = SurgeryNetworkSetting;
    CardPageId = "Surgery Network Setting";
    UsageCategory = Administration;
    InsertAllowed = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Environment Type"; Rec."Environment Type")
                {
                    ToolTip = 'Specifies the value of the Environment Type field.';
                }
                field("Access Token"; Rec."Access Token")
                {
                    ToolTip = 'Specifies the value of the Access Token field.';
                }
                field("API URL"; Rec."API URL")
                {

                }
            }
        }
    }
    actions
    {
        area(Navigation)
        {
            action("Download Sales Orders")
            {
                Image = Download;
                trigger OnAction()
                var
                    cduDonloadOrder: Codeunit "Surgery Network Order Download";
                // rec: Record "Sales Header";
                begin
                    cduDonloadOrder.SurgeryNetworkConnect();
                end;
            }
            action("Delete SN Order")
            {
                Image = Download;
                trigger OnAction()
                var
                    recSugNetOrderHistory: Record SugNetOrderHistory;
                    recSalesHead: Record "Sales Header";
                    recSalesLines: Record "Sales Line";
                begin
                    recSugNetOrderHistory.DeleteAll();

                    recSalesHead.Reset();
                    recSalesHead.SetRange("Surgery Network Header", true);

                    recSalesHead.DeleteAll();



                    recSalesLines.Reset();
                    recSalesLines.SetRange("Surgery Network Lines", true);

                    recSalesLines.DeleteAll();

                end;
            }
            action("Acknowledge SN Order")
            {
                Image = Download;
                trigger OnAction()
                var
                    cduDonloadOrder: Codeunit "Surgery Network Order Download";
                begin
                    cduDonloadOrder.changeSNOrderStatus();
                end;
            }

            action("GMC DateCheck Download Shopify Customers")
            {
                Image = Download;
                trigger OnAction()
                var
                    cu: Codeunit GMCDateCheck;
                begin
                    cu.DownloadShopifyCustomers();

                end;
            }
            action("GMC DateCheck DownloadBCCustomers")
            {
                Image = Download;
                trigger OnAction()
                var
                    cu: Codeunit GMCDateCheck;
                begin
                    cu.DownloadBCCustomers();

                end;
            }

            action("Split Orders")
            {
                Image = Download;
                trigger OnAction()
                var
                    cu: Codeunit SplitOrders;
                    recShoify: Record "Sales Header";
                begin
                    recShoify.Reset();
                    recShoify.SetRange("No.", 'SO01122');
                    if recShoify.FindSet() then begin
                        cu.checkSalesLines(recShoify);
                    end;
                end;
            }
        }
    }
}
