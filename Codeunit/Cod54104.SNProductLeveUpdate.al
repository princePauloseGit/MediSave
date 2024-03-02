codeunit 54104 SNProductLeveUpdate
{
    var
        RESTAPIHelper: Codeunit "REST API Helper";
        NYTJSONMgt: Codeunit "NYT JSON Mgt";
        cu_CommonHelper: Codeunit CommonHelper;

    trigger OnRun()
    begin
        SNProductAPIConnect('', '');
    end;


    procedure SNProductAPIConnect(recItemNO: Code[50]; BlockorDisc: Code[50])
    var
        recItem: Record Item;
        result, url, Description : text;
        rec_SurgeryNetworkSetting: Record SurgeryNetworkSetting;
        quantity: Integer;
        JToken: JsonToken;
        Jarray: JsonArray;
        JObject: JsonObject;
        i: Integer;
        BlockedorDisc: Boolean;
    begin
        BlockedorDisc := false;
        recItem.Reset();

        if recItemNO <> '' then begin
            recItem.SetRange("No.", recItemNO);
        end;

        if BlockorDisc = 'YES' then begin
            BlockedorDisc := true;
        end;

        if recItem.FindSet() then begin
            repeat
                Clear(Description);
                Description := recItem.Description.ToLower();
                if (BlockedorDisc = true) then begin
                    quantity := -2;
                end else
                    if (BlockedorDisc = false) then begin
                        if (Description.Contains('discont') or (recItem.Blocked = true)) then begin
                            quantity := -2;
                        end else
                            quantity := CalculateAvailbleStock(recItem)
                    end;

                rec_SurgeryNetworkSetting.Reset();
                if rec_SurgeryNetworkSetting.Findset() then begin
                    repeat
                        url := rec_SurgeryNetworkSetting."API URL" + '/snapi/ext/medisave/products?authToken=' + rec_SurgeryNetworkSetting."Access Token" + '&fieldName=totalUnits&fieldValue=' + format(quantity) + '&productSKU=' + recItem."No.";
                        RESTAPIHelper.Initialize('PATCH', url);
                        RESTAPIHelper.SetContentType('application/json');

                        if RESTAPIHelper.Send(Format(EnhIntegrationLogTypes::"Surgery Network")) then begin
                            result := RESTAPIHelper.GetResponseContentAsText();

                            if not result.Contains('New SKU cache item added') then begin
                                if Jarray.ReadFrom(result) then begin
                                    for i := 0 to Jarray.Count() - 1 do begin
                                        Jarray.Get(i, Jtoken);
                                        JObject := Jtoken.AsObject();
                                        cu_CommonHelper.InsertEnhancedIntegrationLog(JToken, EnhIntegrationLogTypes::"Surgery Network", 'Product level updated', 'Information');
                                    end
                                end;
                            end else begin
                                cu_CommonHelper.InsertEnhancedIntegrationLog(JToken, EnhIntegrationLogTypes::"Surgery Network", 'Item ' + recItem."No.", 'Error');
                            end;
                        end;
                    until rec_SurgeryNetworkSetting.Next() = 0;
                end;
            until recItem.Next() = 0;
        end;
    end;

    procedure CalculateAvailbleStock(recItem: Record Item): Decimal
    var
        availableStock: Decimal;
    begin
        recItem.CalcFields(Inventory);
        recItem.CalcFields("Qty. on Sales Order");
        recItem.CalcFields("Qty. on Purch. Order");
        availableStock := recItem.Inventory;

        if availableStock > 0 then begin
            exit(availableStock);

        end else
            if availableStock = 0 then begin
                if recItem."Qty. on Purch. Order" > 0 then begin
                    availableStock := -4;
                    exit(availableStock);
                end;
            end else begin
                availableStock := 0;
                exit(availableStock);

            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Sales Document", 'OnBeforePerformManualReleaseProcedure', '', false, false)]
    local procedure setForceUpdate(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean)
    var
        recSalesLine: Record "Sales Line";
        cuReleaseSalesDoc: Codeunit "Release Sales Document";
        recWarehouse: Record "Warehouse Activity Header";
    begin
        recWarehouse.Reset();
        recWarehouse.SetRange("Source No.", SalesHeader."No.");

        if not recWarehouse.FindSet() then begin

            recSalesLine.Reset();
            recSalesLine.SetRange("Document No.", SalesHeader."No.");
            recSalesLine.SetRange("Document Type", "Sales Document Type"::Order);
            if recSalesLine.FindSet() then begin
                repeat
                    SNProductAPIConnect(recSalesLine."No.", '');
                until recSalesLine.Next() = 0;
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Assembly Document", 'OnBeforeReleaseAssemblyDoc', '', false, false)]
    local procedure setForceUpdateforAssemblyOrder(var AssemblyHeader: Record "Assembly Header")
    var
        recAssemblyLine: Record "Assembly Line";

    begin
        recAssemblyLine.Reset();
        recAssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        recAssemblyLine.SetRange("Document Type", "Sales Document Type"::Order);
        if recAssemblyLine.FindSet() then begin
            repeat
                SNProductAPIConnect(recAssemblyLine."No.", '');
            until recAssemblyLine.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Act.-Register (Yes/No)", 'OnBeforeRegisterRun', '', false, false)]
    local procedure setForceUpdateforWarehousePutAway(var WarehouseActivityLine: Record "Warehouse Activity Line")
    var
    begin
        if WarehouseActivityLine.FindSet() then begin
            repeat
                SNProductAPIConnect(WarehouseActivityLine."Item No.", '');
            until WarehouseActivityLine.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Ledger Entry", 'OnAfterInsertEvent', '', false, false)]
    procedure OnAfterInsertEventonItemLedgerEntry(var Rec: Record "Item Ledger Entry")
    var
    begin
        SNProductAPIConnect(Rec."Item No.", '');
    end;
}
