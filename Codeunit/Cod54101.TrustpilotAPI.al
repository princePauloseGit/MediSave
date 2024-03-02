codeunit 54101 "Trustpilot API"
{
    trigger OnRun()
    var
        Rec_TrustpilotAccessToken: Record "Trustpilot Access Token";
        Rec_TrustpilotSetting: Record "Trustpilot Settings";
    begin
        if Rec_TrustpilotSetting.FindFirst() then begin
            if Rec_TrustpilotAccessToken.FindFirst() then begin
                if ShouldRefreshAccessToken(Rec_TrustpilotAccessToken) then begin
                    GetTrustpilotAccessToken(Rec_TrustpilotAccessToken);
                end;
            end else begin
                GetTrustpilotAccessToken(Rec_TrustpilotAccessToken);
            end;
            PostInviteToTrustpilot();
            SendAuditEmail();
        end else begin
            Error('Add the Trustpilot API settings details');
        end;
    end;

    procedure GetTrustpilotAccessToken(accessTokenRecord: Record "Trustpilot Access Token") Result: Text;
    var
        APIUrl: Text;
        RESTAPIHelper: Codeunit RestAPIHelper;
        Base64Convert: Codeunit "Base64 Convert";
        AccessToken: Text;
        Jtoken: JsonToken;
        JObject: JsonObject;
        Rec_TrustpilotAccessToken: Record "Trustpilot Access Token";
        Rec_TrustpilotSetting: Record "Trustpilot Settings";
    begin
        APIUrl := 'https://api.trustpilot.com/v1/oauth/oauth-business-users-for-applications/accesstoken';
        Rec_TrustpilotSetting.FindFirst();
        RESTAPIHelper.Initialize('POST', APIUrl);
        RESTAPIHelper.AddRequestHeader('Authorization', 'Basic ' + Base64Convert.ToBase64(Rec_TrustpilotSetting."Client Id" + ':' + Rec_TrustpilotSetting."Client Secret"));
        RESTAPIHelper.AddBody('grant_type=password&username=' + Rec_TrustpilotSetting.Username + '&password=' + Rec_TrustpilotSetting.Password);
        RESTAPIHelper.SetContentType('application/x-www-form-urlencoded');

        if RESTAPIHelper.Send('Trustpilot') then begin
            JObject.ReadFrom(RESTAPIHelper.GetResponseContentAsText());
            JObject.Get('access_token', Jtoken);
            Result := Jtoken.AsValue().AsText();
            if Rec_TrustpilotAccessToken.Count = 0 then begin
                Rec_TrustpilotAccessToken.Init();
                Rec_TrustpilotAccessToken.Id := CreateGuid();
                Rec_TrustpilotAccessToken."Access Token" := Result;
                Rec_TrustpilotAccessToken."Created Date" := Today();
                Rec_TrustpilotAccessToken.Insert();
            end else begin
                Rec_TrustpilotAccessToken.FindFirst();
                Rec_TrustpilotAccessToken."Access Token" := Result;
                Rec_TrustpilotAccessToken."Created Date" := Today();
                Rec_TrustpilotAccessToken.Modify();
            end;
        end;
    end;

    procedure ShouldRefreshAccessToken(accessTokenRecord: Record "Trustpilot Access Token") Result: Boolean;
    var
        today: Date;
    begin
        today := Today();
        Result := accessTokenRecord."Created Date" <> today;
    end;

    procedure PostInviteToTrustpilot()
    var
        APIUrl, Result, RequestBody : Text;
        RESTAPIHelper: Codeunit RestAPIHelper;
        Base64Convert: Codeunit "Base64 Convert";
        Rec_TrustpilotAccessToken: Record "Trustpilot Access Token";
        Rec_TrustpilotSetting: Record "Trustpilot Settings";
        Rec_SalesHeaderArchive: Record "Sales Header Archive";
        Enum_DocumentType: Enum "Sales Document Type";
    begin
        Rec_SalesHeaderArchive.SetFilter("External Document No.", '<>%1', '');
        Rec_SalesHeaderArchive.SetRange("Document Type", Enum_DocumentType::Order);
        Rec_SalesHeaderArchive.SetFilter("Package Tracking No.", '<>%1', '');
        Rec_SalesHeaderArchive.SetAutoCalcFields(IsPriceZero, CheckedForItem, SelectForReview, IsEligibalForTrustpilotReview, IspersonalisationEngraving, IsInvitedForSalesOrder);
        Rec_SalesHeaderArchive.SetRange(IsEligibalForTrustpilotReview, true);
        Rec_SalesHeaderArchive.SetRange(IsInvitedForSalesOrder, false);
        Rec_SalesHeaderArchive.SetRange(IspersonalisationEngraving, true);
        Rec_SalesHeaderArchive.SetFilter(IsPriceZero, '<>%1', 0);
        Rec_SalesHeaderArchive.SetRange(Ship, true);
        Rec_SalesHeaderArchive.SetRange("Send Trustpilot Invite", true);
        Rec_SalesHeaderArchive.SetRange(IsInvited, false);
        Rec_SalesHeaderArchive.SetRange(CheckedForItem, true);
        Rec_SalesHeaderArchive.SetRange(SelectForReview, true);
        if Rec_SalesHeaderArchive.FindSet(true) then
            repeat
                Clear(RESTAPIHelper);
                Rec_TrustpilotSetting.FindFirst();
                APIUrl := 'https://invitations-api.trustpilot.com/v1/private/business-units/' + Rec_TrustpilotSetting."Business Unit Id" + '/email-invitations';
                RESTAPIHelper.Initialize('Post', APIUrl);
                Rec_TrustpilotAccessToken.FindFirst();
                RESTAPIHelper.SetRequestHeader(Rec_TrustpilotAccessToken."Access Token");
                RESTAPIHelper.SetContentType('application/x-www-form-urlencoded');

                RequestBody := '{ "locale": "en-US","senderEmail":' + '"' + Rec_TrustpilotSetting."Sender Email" + '",';
                RequestBody += '"senderName":' + '"' + Rec_TrustpilotSetting."Sender Name" + '",';
                RequestBody += '"consumerEmail":' + '"' + Rec_SalesHeaderArchive."Sell-to E-Mail" + '",';
                RequestBody += '"consumerName":' + '"' + Rec_SalesHeaderArchive."Sell-to Contact" + '",';
                RequestBody += '"replyTo":' + '"' + Rec_TrustpilotSetting."Replay To Email" + '",';
                RequestBody += '"serviceReviewInvitation": {';
                RequestBody += '"templateId":' + '"' + Rec_TrustpilotSetting."Template Id" + '",';
                //RequestBody += '"preferredSendTime":' + '"' + Format(Today + 7, 0, '<Month,2>/<Day,2>/<Year4>') + ' ' + Format(Time(), 0, '<Hours24>:<Minutes,2>:<Seconds,2>') + '",';
                RequestBody += '"redirectUri":"http://medisave.net"';
                RequestBody += '}';
                RequestBody += '}';
                RESTAPIHelper.AddBody(RequestBody);
                RESTAPIHelper.SetContentType('application/json');

                RESTAPIHelper.Send(Rec_SalesHeaderArchive);

            until Rec_SalesHeaderArchive.Next() = 0;
    end;

    procedure InternalAuditEmail(var "Sales Header Archive": Record "Sales Header Archive");
    var
        Rec_TrustpilotAuditEmail: Record "Trustpilot Audit Email";
    begin
        Rec_TrustpilotAuditEmail.Init();
        Rec_TrustpilotAuditEmail.Id := CreateGuid();
        Rec_TrustpilotAuditEmail."Date/Time" := CurrentDateTime;
        Rec_TrustpilotAuditEmail.Message := 'Order has been sent to Trustpilot successfully - ' + "Sales Header Archive"."No.";
        Rec_TrustpilotAuditEmail."Order No" := "Sales Header Archive"."No.";
        Rec_TrustpilotAuditEmail.Insert();
    end;

    procedure SendAuditEmail()
    var
        cdu_EmailMessage: Codeunit "Email Message";
        cdu_Email: Codeunit Email;
        Subject: Text;
        Body: Text;
        enum_emailSenarios: Enum "Email Scenario";
        Rec_TrustpilotSetting: Record "Trustpilot Settings";
        ToRecipients, CCRecipients, BCCRecipients : List of [Text];
        Rec_TrustpilotAuditEmail: Record "Trustpilot Audit Email";
    begin
        Rec_TrustpilotSetting.FindFirst();
        ToRecipients.Add(Rec_TrustpilotSetting."Audit Email Recipient");
        CCRecipients.Add(Rec_TrustpilotSetting."Audit Email cc");

        Subject := 'Trustpilot Activity';
        Body += '<style>table, th, td {border:1px solid #999999;border-collapse: collapse;text-align:left;}th{padding:5px;background:#ccc;}td{padding:5px;}div{font-family: Calibri;}</style>';
        Body += '<table border="1">';
        Body += '<tr>';
        Body += '<th>Date/Time</th>';
        Body += '<th>Message</th>';
        Body += '<th>Stack Trace</th>';
        Body += '</tr>';
        Body += '</tr>';
        if Rec_TrustpilotAuditEmail.FindSet() then
            repeat
                Body += '<tr>';
                Body += STRSUBSTNO('<td>%1</td>', Rec_TrustpilotAuditEmail."Date/Time");
                Body += STRSUBSTNO('<td>%1</td>', Rec_TrustpilotAuditEmail.Message);
                Body += STRSUBSTNO('<td>%1</td>', Rec_TrustpilotAuditEmail."Stack Trace");
                Body += '</tr>';
            until Rec_TrustpilotAuditEmail.Next() = 0;
        Body += '</table>';
        Body += '<br><br>Kind Regards,<br><br>Business Central';
        cdu_EmailMessage.Create(ToRecipients, Subject, Body, true, CCRecipients, BCCRecipients);

        if Rec_TrustpilotAuditEmail.Count > 0 then begin
            cdu_Email.Send(cdu_EmailMessage, Enum::"Email Scenario"::Default);
            Rec_TrustpilotAuditEmail.DeleteAll();
        end;
    end;
}