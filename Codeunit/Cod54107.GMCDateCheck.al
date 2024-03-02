codeunit 54107 GMCDateCheck
{
    var
        RESTAPIHelper: Codeunit RestAPIHelper;
        NYTJSONMgt: Codeunit "NYT JSON Mgt";
        cu_CommonHelper: Codeunit CommonHelper;
        recShopifyShop: Record "ShopifyAPIConnect";

    trigger OnRun()
    var
    begin
        DownloadShopifyCustomers();
        DownloadBCCustomers();
    end;

    procedure updateGMCExpiry(recCust: Record Customer)
    var
        result, url, body : text;
        DaysExpiry, FormattedDate : Date;
        recShopify: Record ShopifyCustomers;
    begin
        DaysExpiry := cu_CommonHelper.AddDays(365, recCust."GMC Checked");

        recShopify.Reset();
        recShopify.SetRange(BCCustomerNo, recCust."No.");

        if recShopify.FindFirst() then begin
            if recShopify.ShopifyCustomerNo <> '' then begin
                recShopifyShop.Reset();
                if recShopifyShop.FindSet() then begin
                    url := recShopifyShop.URL + '/admin/api/' + recShopifyShop."API Version" + '/customers/' + recShopify.ShopifyCustomerNo + '/metafields.json';
                    body := '{ "metafield": { "namespace" : "custom", "key" : "gmc_expiry", "type" : "date", "value" : "' + format(DaysExpiry, 0, 9) + '" } }';
                    RESTAPIHelper.Initialize('POST', url);

                    //Header
                    RESTAPIHelper.AddRequestHeader('X-Shopify-Access-Token', recShopifyShop."Admin API access token".Trim());
                    //Body
                    RESTAPIHelper.AddBody(body);
                    // //ContentType
                    RESTAPIHelper.SetContentType('application/json');

                    if RESTAPIHelper.Send(Format(EnhIntegrationLogTypes::Shopify)) then begin
                        result := RESTAPIHelper.GetResponseContentAsText();
                        ReadupdateGMCExpiry(result, recShopify.ShopifyCustomerNo, format(DaysExpiry, 0, 9));
                    end;
                end;
            end else begin
                cu_CommonHelper.InsertBusinessCentralErrorLog('There is no Shopify Customer No', recCust."No.", EnhIntegrationLogTypes::Shopify, false, 'Business Customer', EnhIntegrationLogSeverity::Information, 'Shopify Account No not Found');
            end;
        end;
    end;

    procedure DownloadShopifyCustomers()
    var
        result, url : text;
    begin
        recShopifyShop.Reset();
        if recShopifyShop.FindSet() then begin
            url := recShopifyShop.URL + '/admin/api/' + recShopifyShop."API Version" + '/customers.json?&fields=id,updated_at&limit=5';
            while url <> '' do begin
                Clear(RESTAPIHelper);
                RESTAPIHelper.Initialize('GET', url);
                //Header
                RESTAPIHelper.AddRequestHeader('X-Shopify-Access-Token', recShopifyShop."Admin API access token".Trim());

                RESTAPIHelper.SetContentType('application/json');

                if RESTAPIHelper.SendShopify(Format(EnhIntegrationLogTypes::Shopify), url) then begin
                    result := RESTAPIHelper.GetResponseContentAsText();
                    ReadDownloadShopifyCustomersResponse(result);
                end;
            end;
        end;
    end;

    procedure ReadDownloadShopifyCustomersResponse(response: Text)
    var
        recShopify: Record ShopifyCustomers;
        Jtoken, customerToken : JsonToken;
        JObject: JsonObject;
        jsonval: JsonValue;
        Jarray: JsonArray;
        i, j : Integer;
        customerId: Code[50];
    begin
        if not JObject.ReadFrom(response) then
            Error('Invalid response, expected a JSON object');

        if JObject.Get('errors', Jtoken) then begin
            cu_CommonHelper.InsertBusinessCentralErrorLog('No Data Found', '', EnhIntegrationLogTypes::Shopify, false, '', EnhIntegrationLogSeverity::Error, 'No Data found in Shopify');
            exit;
        end;

        JObject.Get('customers', Jtoken);
        if not Jarray.ReadFrom(Format(Jtoken)) then
            Error('Array not Reading Properly');

        for i := 0 to Jarray.Count() - 1 do begin
            Jarray.Get(i, Jtoken);
            Jtoken.AsObject.Get('id', customerToken);
            if not customerToken.AsValue().IsNull then begin
                customerId := customerToken.AsValue().AsCode();

                recShopify.Reset();
                recShopify.SetRange(ShopifyCustomerNo, customerId);

                if not recShopify.FindSet() then begin
                    recShopify.Id := CreateGuid();
                    recShopify.ShopifyCustomerNo := customerId;
                    recShopify.Insert();
                end;
            end
        end;
    end;

    procedure DownloadBCCustomers()
    var
        result, url : text;
        recShopify: Record ShopifyCustomers;
    begin
        recShopify.Reset();
        recShopify.SetFilter(ShopifyCustomerNo, '<>%1', '');
        recShopify.SetFilter(BCCustomerNo, '=%1', '');
        if recShopify.FindSet() then begin
            repeat
                Clear(RESTAPIHelper);

                recShopifyShop.Reset();
                if recShopifyShop.FindSet() then begin
                    url := recShopifyShop.URL + '/admin/api/2022-10/customers/' + recShopify.ShopifyCustomerNo + '/metafields.json';
                    RESTAPIHelper.Initialize('GET', url);
                    //Header
                    RESTAPIHelper.AddRequestHeader('X-Shopify-Access-Token', recShopifyShop."Admin API access token".Trim());
                    RESTAPIHelper.SetContentType('application/json');

                    if RESTAPIHelper.Send(Format(EnhIntegrationLogTypes::Shopify)) then begin
                        result := RESTAPIHelper.GetResponseContentAsText();
                        ReadDownloadBCCustomers(result, recShopify.ShopifyCustomerNo);
                    end;
                end;
            until recShopify.Next() = 0;
        end;
    end;

    procedure ReadDownloadBCCustomers(response: Text; ShopifyCustomerNo: code[50])
    var
        recShopify: Record ShopifyCustomers;
        Jtoken, ownerToken, keyToken, valueToken : JsonToken;
        JObject: JsonObject;
        jsonval: JsonValue;
        Jarray: JsonArray;
        i, j : Integer;
        customerId: Code[50];
        cuCommonHelper: Codeunit CommonHelper;
    begin
        if not JObject.ReadFrom(response) then
            Error('Invalid response, expected a JSON object');

        if JObject.Get('errors', Jtoken) then begin
            cu_CommonHelper.InsertBusinessCentralErrorLog('Invalid Customer ID', ShopifyCustomerNo, EnhIntegrationLogTypes::Shopify, false, 'Customer Id', EnhIntegrationLogSeverity::Error, 'Shopify Account No not Found');
            exit;
        end;

        JObject.Get('metafields', Jtoken);
        if not Jarray.ReadFrom(Format(Jtoken)) then
            Error('Array not Reading Properly');

        if Jarray.Count() = 0 then begin
            cu_CommonHelper.InsertBusinessCentralErrorLog('No Account Found', ShopifyCustomerNo, EnhIntegrationLogTypes::Shopify, false, 'Customer Id', EnhIntegrationLogSeverity::Information, 'Account No not Found');
            exit;
        end;

        for i := 0 to Jarray.Count() - 1 do begin
            Jarray.Get(i, Jtoken);

            Jtoken.AsObject.Get('owner_id', ownerToken);
            Jtoken.AsObject.Get('key', keyToken);
            Jtoken.AsObject.Get('value', valueToken);

            if (not ownerToken.AsValue().IsNull) and (keyToken.AsValue().AsText() = '30_day_id') then begin
                customerId := valueToken.AsValue().AsCode();

                recShopify.Reset();
                recShopify.SetRange(ShopifyCustomerNo, ShopifyCustomerNo);

                if recShopify.FindSet() then begin
                    recShopify.BCCustomerNo := customerId;
                    recShopify.Modify();
                end;
            end;
        end;
    end;

    procedure ReadupdateGMCExpiry(response: Text; ShopifyCustomerNo: code[50]; ExpiryDate: Text)
    var
        recShopify: Record ShopifyCustomers;
        Jtoken, ownerToken, keyToken, valueToken : JsonToken;
        JObject: JsonObject;
        jsonval: JsonValue;
        Jarray: JsonArray;
        i, j : Integer;
        customerId: Code[50];
        cuCommonHelper: Codeunit CommonHelper;
        owner_id: Text;
    begin
        if not JObject.ReadFrom(response) then
            Error('Invalid response, expected a JSON object');

        if JObject.Get('errors', Jtoken) then begin
            cu_CommonHelper.InsertBusinessCentralErrorLog('Invalid Customer ID', ShopifyCustomerNo, EnhIntegrationLogTypes::Shopify, false, 'Customer Id', EnhIntegrationLogSeverity::Error, 'Shopify Account No not Found');
            exit;
        end;

        JObject.Get('metafield', Jtoken);
        JObject := Jtoken.AsObject();

        owner_id := NYTJSONMgt.GetValueAsText(Jtoken, 'owner_id');
        cu_CommonHelper.InsertBusinessCentralErrorLog('GMC Expiry', owner_id, EnhIntegrationLogTypes::Shopify, false, 'Customer Id', EnhIntegrationLogSeverity::Information, 'Shopify Account Expiry date updated to ' + ExpiryDate + ' ');
    end;
}