<%@ WebHandler Language="C#" Class="Order" %>
using System;
using System.Web;
using System.Data;
using System.Data.Common;
using OrclData;
using System.Data.OracleClient;
using System.Text;
using Core;
using System.Net;
using System.IO;
using System.Web.Security;
using System.Xml;

public class Order : IHttpHandler {
    
    public void ProcessRequest (HttpContext context) {
        SQLMos s = new SQLMos();
        string type = context.Request.Params["Judgem"];
        switch (type)
        {
            case "getPayInfo": //获取公众号支付信息(appid,时间戳,随机串,微信签名)
                getPayInfo(context);
                break;
            default:
                break;
        }
    }
    //验证身份
    public bool validateIden(HttpContext context)
    {
        bool b = true;
        string token = context.Request.Headers["x-ol-authtoken-ssl"];
        string openid = PageTool.GetAjaxParameter("Uid");
        string tim = PageTool.GetAjaxParameter("Tim");
        string sql = string.Format(@"select * from wx_user_log t where t.open_id='{0}' and t.token='{1}' and t.time_stamp='{2}' and sysdate<t.close_time",
            openid, token, tim);
        DataTable dt = new DataTable();
        dt = DbHelperWeb.ExecuteTable(CommandType.Text, sql, null);
        if (dt.Rows.Count <= 0)
        {
            b = false;
        }
        return b;
    }
    
    //获取公众号支付信息(appid,时间戳,随机串,微信签名)
    public void getPayInfo(HttpContext context)
    {
            string prepay_id = string.Empty;
            StringBuilder jsonString = new StringBuilder();
            string sql = string.Empty;
            bool b = validateIden(context);
            if (b)
            {
                try
                {
                    string appId = "wxa42d1ee6647fbf6c";
                    //支付密钥
                    string key = "sddsi28dsn28dsafw9qfjendsa923njd";
                    string timeStamp = string.Empty;
                    //微信签名
                    string paySign = string.Empty;
                    //随机数
                    string nonceStr = RandomNum.Str(10);
                    TimeSpan ts = DateTime.UtcNow - new DateTime(1970, 1, 1, 0, 0, 0, 0);
                    timeStamp = Convert.ToInt64(ts.TotalSeconds).ToString();

                    //商品描述
                    string OrderCode = "D" + DateTime.Now.ToString("yyyyMMddHHmmss") + RandomNum.Number(5);
                    string body = "订单号：" + OrderCode;
                    //商户号
                    string mch_id = "1517707671";
                    //通知地址-接收微信支付成功通知
                    string notify_url = "https://wx.olakeji.cn/wxapi/action/notify_url.ashx";
                    //用户标识 -用户在商户appid下的唯一标识
                    //string openid = "oH0A01roiBbjYjipDB9P3XYkuQ0A";
                    string openid = PageTool.GetAjaxParameter("Uid");
                    //商户订单号
                    string out_trade_no = OrderCode;
                    //下单IP
                    string spbill_create_ip = GetIP(context);
                    //总金额 分为单位
                    int total_fee = 1;
                    //交易类型 -JSAPI、NATIVE、APP 如果是生成二维码请填写NATIVE
                    string trade_type = "JSAPI";

                    //微信签名
                    string tmpStr = "appid=" + appId + "&body=" + body + "&mch_id=" + mch_id + "&nonce_str=" + nonceStr + "&notify_url=" + notify_url + "&openid=" + openid + "&out_trade_no=" + out_trade_no + "&spbill_create_ip=" + spbill_create_ip + "&total_fee=" + total_fee + "&trade_type=" + trade_type + "&key=" + key + "";
                    string Getprepay_idSign = FormsAuthentication.HashPasswordForStoringInConfigFile(tmpStr, "MD5").ToUpper();

                    string url = "https://api.mch.weixin.qq.com/pay/unifiedorder";
                    string xml = "<xml>";
                    xml += "<appid>" + appId + "</appid>";
                    xml += "<body>" + body + "</body>";
                    xml += "<mch_id>" + mch_id + "</mch_id>";
                    xml += "<nonce_str>" + nonceStr + "</nonce_str>";
                    xml += "<notify_url>" + notify_url + "</notify_url>";
                    xml += "<openid>" + openid + "</openid>";
                    xml += "<out_trade_no>" + out_trade_no + "</out_trade_no>";
                    xml += "<spbill_create_ip>" + spbill_create_ip + "</spbill_create_ip>";
                    xml += "<total_fee>" + total_fee + "</total_fee>";
                    xml += "<trade_type>" + trade_type + "</trade_type>";
                    xml += "<sign>" + Getprepay_idSign + "</sign>";
                    xml += "</xml>";
                    string v = PostWebRequests(url, xml);
                    //获取的prepay_id
                    prepay_id = v;

                    //获取paySign，请对照前后台的大小写
                    string v_tmpStr = "appId=" + appId + "&nonceStr=" + nonceStr + "&package=prepay_id=" + v + "&signType=MD5&timeStamp=" + timeStamp + "&key=" + key + "";

                    paySign = FormsAuthentication.HashPasswordForStoringInConfigFile(v_tmpStr, "MD5").ToUpper();

                    sql = string.Format(@"insert into wx_order values(wx_order_seq.nextval,'{0}','{1}',{2},sysdate,0,'{3}','{4}','{5}',0)",
                        openid, OrderCode, (total_fee * 1.0) / 100, timeStamp, nonceStr, Getprepay_idSign);
                    DbHelperWeb.ExecuteNonQuery(CommandType.Text, sql, null);
                    jsonString.Append("{");
                    jsonString.Append("\"result\":\"true\",");
                    jsonString.Append("\"payInfo\":[");
                    jsonString.Append("{");
                    jsonString.Append("\"appId\":" + "\"" + appId + "\",");
                    jsonString.Append("\"timeStamp\":" + "\"" + timeStamp + "\",");
                    jsonString.Append("\"nonceStr\":" + "\"" + nonceStr + "\",");
                    jsonString.Append("\"prepay_id\":" + "\"" + prepay_id + "\",");
                    jsonString.Append("\"paySign\":" + "\"" + paySign + "\"");
                    jsonString.Append("}");
                    jsonString.Append("]}");
                }
                catch (Exception e)
                {
                    Utils.apiError(DateTime.Now.ToString() + sql + "调用微信支付报错:", e);
                }
            }
            else
            {
                jsonString.Append("{\"result\":\"validateIdenError\"}");
            }
        context.Response.Write(jsonString.ToString());
        context.Response.End();
    }

    /// <summary>
    /// 获取prepay_id
    /// </summary>
    /// <param name="postUrl"></param>
    /// <param name="menuInfo"></param>
    /// <returns></returns>
    public string PostWebRequests(string postUrl, string menuInfo)
    {
        string returnValue = string.Empty;
        try
        {
            byte[] byteData = Encoding.UTF8.GetBytes(menuInfo);
            Uri uri = new Uri(postUrl);
            HttpWebRequest webReq = (HttpWebRequest)WebRequest.Create(uri);
            webReq.Method = "POST";
            webReq.ContentType = "application/x-www-form-urlencoded";
            webReq.ContentLength = byteData.Length;
            //定义Stream信息
            Stream stream = webReq.GetRequestStream();
            stream.Write(byteData, 0, byteData.Length);
            stream.Close();
            //获取返回信息
            HttpWebResponse response = (HttpWebResponse)webReq.GetResponse();
            StreamReader streamReader = new StreamReader(response.GetResponseStream(), Encoding.UTF8);
            returnValue = streamReader.ReadToEnd();
            //关闭信息
            streamReader.Close();
            response.Close();
            stream.Close();

            XmlDocument doc = new XmlDocument();
            doc.LoadXml(returnValue);
            XmlNodeList list = doc.GetElementsByTagName("xml");
            XmlNode xn = list[0];
            string prepay_ids = xn.SelectSingleNode("//prepay_id").InnerText;
            return prepay_ids;
            //如果是二维码扫描，请返回下边的code_url，然后自己再更具内容生成二维码即可
            //string code_url = xn.SelectSingleNode("//prepay_id").InnerText;
            //return code_url;
        }
        catch (Exception ex)
        {
            Utils.apiError(new DateTime().ToString() + "发生错误:", ex);
            return "";
        }
    }

    /// <summary>
    /// 获取用户IP方法
    /// </summary>
    /// <param name="hc"></param>
    /// <returns></returns>
    public static string GetIP(HttpContext hc)
    {
        string ip = string.Empty;

        try
        {
            if (hc.Request.ServerVariables["HTTP_VIA"] != null)
            {
                ip = hc.Request.ServerVariables["HTTP_X_FORWARDED_FOR"].ToString();
            }
            else
            {

                ip = hc.Request.ServerVariables["REMOTE_ADDR"].ToString();
            }
            if (ip == string.Empty)
            {
                ip = hc.Request.UserHostAddress;
            }
            return ip;
        }
        catch
        {
            return "";
        }
    }
    
    public bool IsReusable {
        get {
            return false;
        }
    }

}