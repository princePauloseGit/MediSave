codeunit 54102 RestAPIHelper
{
    Access = Public;
    //TODO: Build in RequestCatcher.com functionality so that it's easy to analyze requests that come from Business Central

    var
        WebClient: HttpClient;
        WebRequest: HttpRequestMessage;
        WebResponse: HttpResponseMessage;
        WebRequestHeaders: HttpHeaders;
        WebContentHeaders: HttpHeaders;
        WebContent: HttpContent;
        CurrentContentType: Text;
        RestHeaders: TextBuilder;
        ContentTypeSet: Boolean;
        cduCommonHelper, cu_CommonHelper : Codeunit "CommonHelper";

    procedure GetBaseURl(): Text
    var
        ApiUrl, baseAPIUrl, i : Text;
        baseurlList: List of [Text];
        rec_CommonUrl: Record CommonURL;
    begin
        if rec_CommonUrl.FindLast() then
            ApiUrl := rec_CommonUrl.URL;
        if ApiUrl.EndsWith('/') then
            baseAPIUrl := ApiUrl + 'api/'
        else
            baseAPIUrl := ApiUrl + '/api/';
        exit(baseAPIUrl);
    end;

    procedure Initialize(Method: Text; URI: Text);
    begin
        WebRequest.Method := Method;
        WebRequest.SetRequestUri(URI);

        WebRequest.GetHeaders(WebRequestHeaders);
    end;

    procedure AddRequestHeader(HeaderKey: Text; HeaderValue: Text)
    begin
        RestHeaders.AppendLine(HeaderKey + ': ' + HeaderValue);
        WebRequestHeaders.Add(HeaderKey, HeaderValue);
    end;

    procedure SetRequestHeader(AccessToken: Text)
    begin
        WebClient.DefaultRequestHeaders.Add('Authorization', 'Bearer ' + AccessToken);
    end;

    procedure AddBody(Body: Text)
    begin
        WebContent.WriteFrom(Body);
        ContentTypeSet := true;
    end;

    procedure SetContentType(ContentType: Text)
    begin
        CurrentContentType := ContentType;
        webcontent.GetHeaders(WebContentHeaders);
        if WebContentHeaders.Contains('Content-Type') then
            WebContentHeaders.Remove('Content-Type');
        WebContentHeaders.Add('Content-Type', ContentType);
    end;

    procedure SendShopify(MarketPlace: Code[20]; var PaginationURL: Text) SendSuccess: Boolean
    var
        StartDateTime: DateTime;
        TotalDuration: Duration;
        RequestUrl, description, ebayError, outputString : Text;
        Outstr: OutStream;
        cduCommonHelper: Codeunit "Common Helper";
        contentHeaders: HttpHeaders;
        ListOfKeys: list of [text];
        ListOfValues: list of [Text];
        HeaderKey: text;
        element: Integer;
    begin
        if ContentTypeSet then
            WebRequest.Content(WebContent);

        OnBeforeSend(WebRequest, WebResponse);
        StartDateTime := CurrentDateTime();
        WebClient.Timeout := 300000;
        //WebClient.Timeout := 1800000;
        SendSuccess := WebClient.Send(WebRequest, WebResponse);
        TotalDuration := CurrentDateTime() - StartDateTime;
        OnAfterSend(WebRequest, WebResponse);
        if SendSuccess then begin
            if not WebResponse.IsSuccessStatusCode() then begin
                SendSuccess := false;
                WebResponse.Content().ReadAs(outputString);
                cduCommonHelper.InsertPaymentDownloadErrorLog(WebResponse.ReasonPhrase, WebResponse.HttpStatusCode, MarketPlace);
            end else begin
                contentHeaders := WebResponse.Headers;
                ListOfKeys := contentHeaders.Keys();
                foreach HeaderKey in ListOfKeys do begin
                    //read each httpheader key
                    //function GetValues should return List of Values, not array
                    if (HeaderKey = 'Link') or (HeaderKey = 'link') then begin
                        contentHeaders.GetValues(HeaderKey, ListOfValues);
                        for element := 1 to ListOfValues.Count do begin
                            PaginationURL := ListOfValues.Get(element);
                            ResponseHeaderLinkExtractor(PaginationURL);
                        end
                    end;
                end;
            end;

        end else begin
            cduCommonHelper.InsertPaymentDownloadErrorLog(WebResponse.ReasonPhrase, WebResponse.HttpStatusCode, MarketPlace);
        end;
    end;

    procedure Send(MarketPlace: Code[20]) SendSuccess: Boolean
    var
        StartDateTime: DateTime;
        TotalDuration: Duration;
        RequestUrl, description, ebayError, outputString : Text;
        Outstr: OutStream;
    begin
        if ContentTypeSet then
            WebRequest.Content(WebContent);

        OnBeforeSend(WebRequest, WebResponse);
        StartDateTime := CurrentDateTime();
        WebClient.Timeout := 300000;
        SendSuccess := WebClient.Send(WebRequest, WebResponse);

        TotalDuration := CurrentDateTime() - StartDateTime;
        OnAfterSend(WebRequest, WebResponse);
        if SendSuccess then begin
            if not WebResponse.IsSuccessStatusCode() then begin
                SendSuccess := false;
                cduCommonHelper.InsertBusinessCentralErrorLog(GetResponseReasonPhrase(), 'Status code: ' + format(GetHttpStatusCode()), EnhIntegrationLogTypes::Trustpilot, true, '', EnhIntegrationLogSeverity::Error, 'Failed To Generate Access Token');
            end;
        end;
    end;

    procedure Send(SalesHeaderArchive: Record "Sales Header Archive") SendSuccess: Boolean
    var
        StartDateTime: DateTime;
        TotalDuration: Duration;
        RequestUrl, description, ebayError, outputString : Text;
        Outstr: OutStream;
        TrustpilotAPI: Codeunit "Trustpilot API";
    begin
        if ContentTypeSet then
            WebRequest.Content(WebContent);

        OnBeforeSend(WebRequest, WebResponse);
        StartDateTime := CurrentDateTime();
        WebClient.Timeout := 300000;
        //WebClient.Timeout := 1800000;
        SendSuccess := WebClient.Send(WebRequest, WebResponse);

        TotalDuration := CurrentDateTime() - StartDateTime;
        OnAfterSend(WebRequest, WebResponse);
        if SendSuccess then begin
            if 202 = GetHttpStatusCode() then begin
                TrustpilotAPI.InternalAuditEmail(SalesHeaderArchive);
                cduCommonHelper.InsertBusinessCentralErrorLog(GetResponseReasonPhrase(), 'Status code: ' + format(GetHttpStatusCode()), EnhIntegrationLogTypes::Trustpilot, true, 'Send Trustpilot invite for order ' + SalesHeaderArchive."No.", EnhIntegrationLogSeverity::Information, 'Success');
                SalesHeaderArchive.IsInvited := true;
                SalesHeaderArchive.Modify();
            end;
            if not WebResponse.IsSuccessStatusCode() then begin
                SendSuccess := false;
                cduCommonHelper.InsertBusinessCentralErrorLog(GetResponseReasonPhrase(), 'Status code: ' + format(GetHttpStatusCode()), EnhIntegrationLogTypes::Trustpilot, true, '', EnhIntegrationLogSeverity::Error, 'Failed To Send Invite');
            end;
        end;
    end;

    procedure GetResponseContentAsText() ResponseContentText: Text
    var
        RestBlob: Codeunit "Temp Blob";
        Instr: Instream;
    begin

        RestBlob.CreateInStream(Instr);
        WebResponse.Content().ReadAs(ResponseContentText);
    end;

    procedure GetResponseReasonPhrase(): Text
    begin
        exit(WebResponse.ReasonPhrase);
    end;

    procedure ResponseHeaderLinkExtractor(var PaginationURL: Text)
    var
        HeaderLines: list of [Text];
        Line: Text;
        NextURL: Text;
        Position: Integer;
        Separators: List of [Text];
    begin
        Separators.Add(',');
        // ResponseHeader := '<https://firstaidsaveuk.myshopify.com/admin/api/2022-10/customers.json?limit=5&fields=id%2Cupdated_at&page_info=eyJkaXJlY3Rpb24iOiJwcmV2IiwibGFzdF9pZCI6NzEwNjI2MjgyNzMxNSwibGFzdF92YWx1ZSI6MTY5MDI3Nzg2ODAwMH0>; rel="previous", <https://firstaidsaveuk.myshopify.com/admin/api/2022-10/customers.json?limit=5&fields=id%2Cupdated_at&page_info=eyJkaXJlY3Rpb24iOiJuZXh0IiwibGFzdF9pZCI6Njg5MzM0OTYwMTU4NywibGFzdF92YWx1ZSI6MTY4MTM4NzM1MTAwMH0>; rel="next"';

        // ResponseHeader := '<https://firstaidsaveuk.myshopify.com/admin/api/2022-10/customers.json?limit=5&fields=id%2Cupdated_at&page_info=eyJsYXN0X2lkIjo3NTE3NDEzMzEwNzcxLCJsYXN0X3ZhbHVlIjoxNzAxNzcyMTUwMDAwLCJkaXJlY3Rpb24iOiJuZXh0In0>; rel="next"';

        HeaderLines := PaginationURL.Split(Separators);

        foreach Line in HeaderLines do begin
            if Line.Contains('rel="next"') then begin
                Position := Text.StrPos(Line, '<');
                if Position > 0 then begin
                    NextURL := Line.Substring(Position);
                    NextURL := NextURL.Replace('<', '');
                    NextURL := NextURL.Replace('>', '');
                    NextURL := NextURL.Replace('; rel="next"', '');
                    PaginationURL := NextURL;
                    break;
                end;
            end else begin
                PaginationURL := '';
            end;
        end;
    end;

    procedure GetHttpStatusCode(): Integer
    begin
        exit(WebResponse.HttpStatusCode());
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSend(WebRequest: HttpRequestMessage; WebResponse: HttpResponseMessage)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterSend(WebRequest: HttpRequestMessage; WebResponse: HttpResponseMessage)
    begin
    end;
}