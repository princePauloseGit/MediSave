codeunit 54105 "Surgery Network Order Download"
{
    var
        RESTAPIHelper: Codeunit "REST API Helper";
        NYTJSONMgt: Codeunit "NYT JSON Mgt";
        cu_CommonHelper: Codeunit CommonHelper;

    trigger OnRun()
    begin
        SurgeryNetworkConnect();
        changeSNOrderStatus();
    end;

    procedure SurgeryNetworkConnect()
    var
        result, url : text;
        rec_SurgeryNetworkSetting: Record SurgeryNetworkSetting;
    begin
        Clear(RESTAPIHelper);
        Clear(url);
        url := RESTAPIHelper.GetBaseURl() + 'SurgeryNetwork/GetOrders';

        rec_SurgeryNetworkSetting.Reset();
        if rec_SurgeryNetworkSetting.FindSet() then begin
            repeat
                RESTAPIHelper.Initialize('POST', url);
                RESTAPIHelper.AddRequestHeader('authToken', rec_SurgeryNetworkSetting."Access Token".Trim());
                RESTAPIHelper.AddRequestHeader('environment', format(rec_SurgeryNetworkSetting."Environment Type".AsInteger()));
                //ContentType
                RESTAPIHelper.SetContentType('application/json');

                if RESTAPIHelper.Send(Format(EnhIntegrationLogTypes::"Surgery Network")) then begin
                    result := RESTAPIHelper.GetResponseContentAsText();
                    ReadApiResponse(result, rec_SurgeryNetworkSetting);
                end;
            until rec_SurgeryNetworkSetting.Next() = 0;
        end;
    end;

    local procedure ReadApiResponse(var apiResponse: Text; var rec_SurgeryNetworkSetting: Record SurgeryNetworkSetting)
    var
        varJsonArray: JsonArray;
        varjsonToken: JsonToken;
        index: Integer;
        OrderId: Code[40];
        JObject: JsonObject;
        rec_EnhanceIntegrationLog: Record EnhancedIntegrationLog;
        NYTJSONMgt: Codeunit "NYT JSON Mgt";
        cdu_CommonHelper: Codeunit "Common Helper";
        description: Text;
    begin
        if not JObject.ReadFrom(apiResponse) then
            Error('Invalid response, expected a JSON object');

        JObject.Get('orders', varjsonToken);

        if not varJsonArray.ReadFrom(Format(varjsonToken)) then
            Error('Array not Reading Properly');

        if varJsonArray.ReadFrom(Format(varjsonToken)) then begin

            for index := 0 to varJsonArray.Count - 1 do begin
                varJsonArray.Get(index, varjsonToken);

                Clear(OrderId);
                OrderId := NYTJSONMgt.GetValueAsText(varjsonToken, 'orderNumber');

                //Insert sales header
                if not InsertSalesHeader(varjsonToken, OrderId, rec_SurgeryNetworkSetting) then begin
                    description := 'Entry for OrderId ' + OrderId + ' is failed to download';
                    cdu_CommonHelper.InsertBusinessCentralErrorLog(description, OrderId, EnhIntegrationLogTypes::"Surgery Network", false);
                end;
            end;
        end;

        //Insert error logs from api data
        JObject.Get('errorLogs', varjsonToken);

        if not varJsonArray.ReadFrom(Format(varjsonToken)) then
            Error('Array not Reading Properly');

        for index := 0 to varJsonArray.Count() - 1 do begin
            varJsonArray.Get(index, varjsonToken);
            cdu_CommonHelper.InsertEnhancedIntegrationLog(varjsonToken, EnhIntegrationLogTypes::"Surgery Network");
        end;
    end;

    //Procedure to insert Sales header data
    [TryFunction]
    procedure InsertSalesHeader(varjsonToken: JsonToken; SNOrderId: Code[20]; rec_SurgeryNetworkSetting: Record SurgeryNetworkSetting)
    var
        recSalesHeader: Record "Sales Header";
        recSalesInvoiceHeader: Record "Sales Invoice Header";
        recSugNetOrderHistory: Record SugNetOrderHistory;
        i, j, lineNo, lineCount, count : Integer;
        varJsonArray, responseArray : JsonArray;
        addressesToken, billingAddressToken, shippingAddressToken, OrderLineToken, totalPriceToken : JsonToken;
        TotalAmount: Decimal;
        ItemNo: Code[40];
        shipToPostcode, description, fullAddress, city, county, postcode, singleAddress, mainAddress : Text;
        itemNotExist, LineNotInserted : Boolean;
        recItem: Record Item;
        ReleaseSalesDoc: Codeunit "Release Sales Document";
        SalesHeaderNo: Code[20];
        ListofAddress, ListofAddressValue : List of [Text];
    begin
        Clear(shipToPostcode);
        Clear(OrderLineToken);
        Clear(NYTJSONMgt);
        Clear(addressesToken);
        Clear(shippingAddressToken);
        Clear(billingAddressToken);

        recSalesHeader.Reset();
        recSugNetOrderHistory.Reset();
        recSugNetOrderHistory.SetRange(OrderId, SNOrderId);

        if not recSugNetOrderHistory.FindFirst() then begin

            recSalesHeader.SetRange("External Document No.", SNOrderId);

            if not recSalesHeader.FindFirst() then begin

                recSalesInvoiceHeader.SetRange("External Document No.", SNOrderId);

                if not recSalesInvoiceHeader.FindFirst() then begin

                    varjsonToken.SelectToken('orderLines', OrderLineToken);

                    if OrderLineToken.IsArray then begin
                        responseArray := OrderLineToken.AsArray();

                        for j := 0 to responseArray.Count - 1 do begin
                            responseArray.Get(j, OrderLineToken);

                            ItemNo := NYTJSONMgt.GetValueAsText(OrderLineToken, 'supplierId');

                            recItem.SetRange("No.", ItemNo);

                            //Check if item present in item table or not
                            if recItem.FindFirst() then begin
                                if recItem.Blocked then begin
                                    description := 'This item ' + ItemNo + ' is blocked';
                                    cu_CommonHelper.InsertBusinessCentralErrorLog(description, SNOrderId, EnhIntegrationLogTypes::"Surgery Network", true, 'Order', EnhIntegrationLogSeverity::Error, 'Sales order not created');
                                end;
                            end
                            else begin
                                itemNotExist := true;
                                description := 'This Item not found ' + ItemNo + ' so failed to download the order';
                                cu_CommonHelper.InsertBusinessCentralErrorLog(description, SNOrderId, EnhIntegrationLogTypes::"Surgery Network", true, 'Order Id', EnhIntegrationLogSeverity::Error, 'Sales order not created');
                            end;
                        end;
                    end;

                    if itemNotExist = false then begin
                        recSalesHeader.Init();
                        recSalesHeader.InitRecord;
                        recSalesHeader."No." := '';
                        recSalesHeader."Document Type" := "Sales Document Type"::Order;
                        recSalesHeader."External Document No." := NYTJSONMgt.GetValueAsText(varjsonToken, 'orderNumber');
                        recSalesHeader."Your Reference" := NYTJSONMgt.GetValueAsText(varjsonToken, 'orderNumber');
                        varjsonToken.SelectToken('buyer', addressesToken);

                        if addressesToken.IsObject then begin

                            fullAddress := NYTJSONMgt.GetValueAsText(addressesToken, 'address');
                            ListofAddress := fullAddress.Split(',');

                            foreach singleAddress in ListofAddress do begin
                                ListofAddressValue.Add(singleAddress);
                            end;

                            count := 0;
                            foreach singleAddress in ListofAddressValue do begin
                                count := count + 1;
                                if (count = 1) then begin
                                    mainAddress := singleAddress;
                                end;
                                if (count = 2) then begin
                                    city := singleAddress
                                end;
                                if (count = 3) then begin
                                    county := singleAddress
                                end;
                                if (count = 4) then begin
                                    postcode := singleAddress
                                end;
                            end;

                            recSalesHeader."Sell-to E-Mail" := NYTJSONMgt.GetValueAsText(addressesToken, 'email');
                            recSalesHeader.Validate("Sell-to E-Mail");
                            recSalesHeader."Sell-to Customer No." := NYTJSONMgt.GetValueAsText(addressesToken, 'code');
                            recSalesHeader.Validate("Sell-to Customer No.");

                            recSalesHeader."Ship-to Name" := NYTJSONMgt.GetValueAsText(addressesToken, 'name');
                            recSalesHeader."Ship-to Address" := mainAddress;
                            recSalesHeader."Ship-to City" := city;
                            recSalesHeader."Ship-to County" := county;
                            recSalesHeader."Ship-to Post Code" := postcode;
                            recSalesHeader."Sell-to Phone No." := NYTJSONMgt.GetValueAsText(addressesToken, 'phone');
                            recSalesHeader."Ship-to Contact" := CopyStr(NYTJSONMgt.GetValueAsText(addressesToken, 'contactName'), 1, 100);

                            recSalesHeader."Bill-to Address" := mainAddress;
                            recSalesHeader."Bill-to City" := city;
                            recSalesHeader."Bill-to County" := county;
                            recSalesHeader."Bill-to Post Code" := postcode;
                            recSalesHeader."Bill-to Name" := NYTJSONMgt.GetValueAsText(addressesToken, 'name');
                            recSalesHeader."Bill-to Contact" := CopyStr(NYTJSONMgt.GetValueAsText(addressesToken, 'contactName'), 1, 100);
                        end;
                        recSalesHeader."Order Batch" := 'Priority Hold';

                        recSalesHeader."Surgery Network Header" := true;
                        recSalesHeader.Insert(true);
                        Commit();

                        SalesHeaderNo := recSalesHeader."No.";

                        //Call sales line procedure
                        varjsonToken.SelectToken('orderLines', OrderLineToken);

                        if OrderLineToken.IsArray then begin

                            responseArray := OrderLineToken.AsArray();

                            for j := 0 to responseArray.Count - 1 do begin

                                lineNo := 10000 + (j * 10000);
                                responseArray.Get(j, OrderLineToken);
                                if not InsertSalesLine(varjsonToken, OrderLineToken, recSalesHeader."No.", lineNo, false, shipToPostcode) then begin

                                    recSalesHeader.Delete(true);
                                    ItemNo := NYTJSONMgt.GetValueAsText(OrderLineToken, 'supplierId');
                                    description := 'In Order ' + SNOrderId + ' entry for Orderline ' + ItemNo + ' is failed to download';
                                    cu_CommonHelper.InsertBusinessCentralErrorLog(description, SNOrderId, EnhIntegrationLogTypes::"Surgery Network", false, 'Order Id',
                                EnhIntegrationLogSeverity::Error, 'Sales order not created');
                                    LineNotInserted := true;
                                end;
                            end;
                            if LineNotInserted = false then begin

                                lineNo := lineNo + 10000;

                                if not InsertSalesLine(varjsonToken, OrderLineToken, recSalesHeader."No.", lineNo, true, shipToPostcode) then begin
                                    recSalesHeader.Delete(true);
                                    description := 'Entry for item Carriage charge is failed to download';
                                    cu_CommonHelper.InsertBusinessCentralErrorLog(description, SNOrderId, EnhIntegrationLogTypes::"Surgery Network", false, 'Order Id', EnhIntegrationLogSeverity::Error, 'Sales order not created');

                                end;

                                recSalesHeader.Reset();
                                recSalesHeader.SetRange("No.", SalesHeaderNo);

                                if recSalesHeader.FindFirst() then begin
                                    ReleaseSalesDoc.ReleaseSalesHeader(recSalesHeader, false);
                                    Commit();
                                end;

                                //Insert data into legacy orders table
                                recSugNetOrderHistory.Init();
                                recSugNetOrderHistory.OrderId := recSalesHeader."External Document No.";
                                recSugNetOrderHistory.Insert(true);
                            end;
                        end;
                    end;
                end;
            end;
        end;
        Commit();
    end;

    [TryFunction]
    //procedure to insert records into Sales Line table
    local procedure InsertSalesLine(var varjsonToken: JsonToken; OrderLineToken: JsonToken; var documnetNo: Code[20]; var lineNo: Integer; carriageflag: Boolean; shipToPostcode: Text)
    var
        recSalesLine: Record "Sales Line";
        recItem: Record Item;
        ItemNo: Code[30];
        quantity: Integer;
        UnitPriceIncludingVat, UnitPriceExcludingVat, VatPercentage, UnitPriceFromApi, TotalAmount, carriageCharge : Decimal;
        priceToken, totalAmounttoken : JsonToken;

    begin
        recSalesLine.Init();
        recSalesLine."Line No." := lineNo;
        recSalesLine."Document No." := documnetNo;
        recSalesLine."Document Type" := "Sales Document Type"::Order;
        recSalesLine.Type := "Sales Line Type"::Item;

        // Insert the Sales line from api data
        if not carriageflag then begin
            recSalesLine."No." := NYTJSONMgt.GetValueAsText(OrderLineToken, 'supplierId');
            recSalesLine.Validate("No.");
            ItemNo := NYTJSONMgt.GetValueAsText(OrderLineToken, 'supplierId');
            quantity := NYTJSONMgt.GetValueAsDecimal(OrderLineToken, 'quantity');
            recSalesLine.Quantity := quantity;
            recSalesLine.Validate(Quantity);
            recSalesLine."Unit Price" := NYTJSONMgt.GetValueAsDecimal(OrderLineToken, 'unitPrice');
            recSalesLine.Validate("Unit Price");
            recSalesLine."SN Transaction Id" := NYTJSONMgt.GetValueAsDecimal(OrderLineToken, 'transactionId');
        end

        // Insert sales line for carriage item
        else begin
            recSalesLine."No." := 'PRIORITY2';
            recSalesLine.Validate("No.");
            recSalesLine.Quantity := 1;
            recSalesLine.Validate(Quantity);

            varjsonToken.SelectToken('total', totalAmounttoken);

            if totalAmounttoken.IsObject then begin
                TotalAmount := NYTJSONMgt.GetValueAsDecimal(totalAmounttoken, 'grandTotal');
                if TotalAmount < 30 then begin
                    carriageCharge := 5;
                end
                else begin
                    carriageCharge := 0;
                end;
            end;
            recSalesLine."Unit Price" := carriageCharge;
            recSalesLine.Validate("Unit Price");
        end;

        recSalesLine."Surgery Network Lines" := true;
        recSalesLine.Insert(true);
        Commit();

        // Reserve the sales line 
        if recSalesLine."No." <> 'PRIORITY2' then begin
            TryReserve(recSalesLine."Document No.");
        end;

        // Reserve the quantity to assemble for assembly item
        if recSalesLine.IsAsmToOrderRequired() then begin
            recSalesLine.AutoAsmToOrder();
        end;
    end;

    procedure TryReserve(ordno: code[20])
    var
        SalesSetup: Record "Sales & Receivables Setup";
        Item: Record Item;
        ReservMgt: Codeunit "Reservation Management";
        ConfirmManagement: Codeunit "Confirm Management";
        QtyToReserve: Decimal;
        QtyToReserveBase: Decimal;
        sl: record "Sales Line";
        itm: record item;
        fullAuto: Boolean;
        SalesLineReserve: Codeunit "Sales Line-Reserve";
    begin
        fullAuto := true;
        sl.SetRange("Document Type", sl."Document Type"::Order);
        sl.SetRange("Document No.", ordno);
        sl.SetRange(Type, sl.Type::Item);
        if sl.findset() then
            repeat
                if itm.Get(sl."No.") then
                    if sl."Reserved Quantity" < sl.Quantity then
                        if itm.Type = itm.Type::Inventory then
                            if itm.Reserve = itm.Reserve::Always then begin
                                SalesLineReserve.ReservQuantity(sl, QtyToReserve, QtyToReserveBase);
                                if QtyToReserveBase <> 0 then begin
                                    ReservMgt.SetReservSource(sl);
                                    ReservMgt.AutoReserve(fullAuto, '', today, QtyToReserve, QtyToReserveBase);
                                end;
                            end;
            until sl.Next() = 0;
    end;

    procedure changeSNOrderStatus()
    var
        result, url, description : text;
        recSugNetOrderHistory: Record SugNetOrderHistory;
        rec_SurgeryNetworkSetting: Record SurgeryNetworkSetting;
    begin
        rec_SurgeryNetworkSetting.Reset();
        if rec_SurgeryNetworkSetting.Findset() then begin
            repeat
                recSugNetOrderHistory.Reset();
                recSugNetOrderHistory.SetRange(IsSent, false);
                if recSugNetOrderHistory.FindSet() then begin
                    repeat
                        url := rec_SurgeryNetworkSetting."API URL" + recSugNetOrderHistory.OrderId + '?authToken=' + rec_SurgeryNetworkSetting."Access Token" + '&newStatus=processing';
                        RESTAPIHelper.Initialize('PATCH', url);
                        RESTAPIHelper.SetContentType('application/json');

                        if RESTAPIHelper.Send(Format(EnhIntegrationLogTypes::"Surgery Network")) then begin
                            result := RESTAPIHelper.GetResponseContentAsText();
                        end;

                        if result = 'true' then begin
                            recSugNetOrderHistory.IsSent := true;
                            recSugNetOrderHistory.Modify(true);
                        end else begin
                            description := 'Failed to change the order status';
                            cu_CommonHelper.InsertBusinessCentralErrorLog(description, recSugNetOrderHistory.OrderId, EnhIntegrationLogTypes::"Surgery Network", false, 'Order Id', EnhIntegrationLogSeverity::Error, '');
                        end;

                    until recSugNetOrderHistory.Next() = 0;
                end;
            until rec_SurgeryNetworkSetting.Next() = 0;
        end;
    end;
}
