<%@ WebHandler Language="C#" Class="notify_url" %>

using System;
using System.Web;
using Core;
using System.Xml;
using System.Data;
using OrclData;

public class notify_url : IHttpHandler {
    
    public void ProcessRequest (HttpContext context) {
        SQLMos s = new SQLMos();
        context.Response.ContentType = "text/plain";
        string wxNotifyXml = "";
        try
        {
            byte[] bytes = context.Request.BinaryRead(context.Request.ContentLength);
            wxNotifyXml = System.Text.Encoding.UTF8.GetString(bytes);
            if (wxNotifyXml.Length == 0)
            {
                return;
            }
            XmlDocument xmldoc = new XmlDocument();

            xmldoc.LoadXml(wxNotifyXml);
            string returnCode = xmldoc.SelectSingleNode("/xml/return_code").InnerText;
            string resultCode = xmldoc.SelectSingleNode("/xml/result_code").InnerText;
            string openId = xmldoc.SelectSingleNode("/xml/openid").InnerText;
            string orderCode = xmldoc.SelectSingleNode("/xml/out_trade_no").InnerText;
            string sign = xmldoc.SelectSingleNode("/xml/sign").InnerText;
            decimal money = decimal.Parse(xmldoc.SelectSingleNode("/xml/total_fee").InnerText);
            string nonceStr = xmldoc.SelectSingleNode("/xml/nonce_str").InnerText;
            string sql = "";
            if (resultCode == "SUCCESS" && returnCode == "SUCCESS")
            {
                sql = "select * from wx_order t where t.order_code='" + orderCode + "' and t.noncestr='" + nonceStr + "'";
                DataTable dt = new DataTable();
                dt = DbHelperWeb.ExecuteTable(CommandType.Text, sql, null);
                if (dt.Rows.Count > 0)
                {
                    decimal d = decimal.Parse(dt.Rows[0]["money"].ToString()) * 100;
                    if (money == d)
                    {
                        sql = "update wx_order t set t.status=1 where t.order_code='" + orderCode + "' and t.noncestr='" + nonceStr + "'";
                        DbHelperWeb.ExecuteNonQuery(CommandType.Text, sql, null);
                        sql = string.Format("insert into wx_business_record values(wx_business_record_seq.nextval,'{0}','{1}','{2}',sysdate)",
                            wxNotifyXml, openId, orderCode);
                        DbHelperWeb.ExecuteNonQuery(CommandType.Text, sql, null);
                    }
                }

            }
        }
        catch (Exception e)
        {
            Utils.apiError(wxNotifyXml, e);
        }
        context.Response.Write(wxNotifyXml);
        context.Response.End();
    }
 
    public bool IsReusable {
        get {
            return false;
        }
    }

}