<%@ WebHandler Language="C#" Class="User" %>

using System;
using System.Web;
using System.Data;
using System.Data.Common;
using OrclData;
using System.Data.OracleClient;
using System.Text;
using Core;

public class User : IHttpHandler {

    public void ProcessRequest(HttpContext context)
    {
        SQLMos s = new SQLMos();
        string type = context.Request.Params["Judgem"];
        switch (type)
        {
            case "getUserInfo": //获取用户信息
                getUserInfo(context);
                break;
            case "getValidateCode"://获取注册验证码
                getValidateCode(context);
                break;
            case "getRegisterMobile"://提交验证码
                getRegisterMobile(context);
                break;
            case "addProvideCustomer"://提交报单
                addProvideCustomer(context);
                break;
            case "addUserExt":
                addUserExt(context);//提交用户信息
                break;
            case "getUserExt"://获取用户信息
                getUserExt(context);
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
    
    //获取用户信息
    public void getUserInfo(HttpContext context)
    {
        StringBuilder jsonString = new StringBuilder();
        bool b = validateIden(context);
        if (b)
        {
            string openid = PageTool.GetAjaxParameter("Uid");
            string sql = string.Format("select t.nick_name,t.link_phone,t.grade,t.head_img from wx_user t where t.open_id='{0}'", openid);
            DataTable dt = new DataTable();
            dt = DbHelperWeb.ExecuteTable(CommandType.Text, sql, null);
            if (dt.Rows.Count > 0)
            {
                jsonString.Append("{");
                jsonString.Append("\"result\":\"true\",");
                jsonString.Append("\"name\"" + ":\"" + dt.Rows[0]["nick_name"].ToString() + "\",");
                string phone = dt.Rows[0]["link_phone"].ToString();
                string phoneStr = "";
                if (!string.IsNullOrEmpty(phone))
                {
                    phoneStr = phone.Substring(0, 3) + "****" + phone.Substring(7);
                }
                jsonString.Append("\"linkphone\"" + ":\"" + phoneStr + "\",");
                jsonString.Append("\"grade\"" + ":\"" + dt.Rows[0]["grade"].ToString() + "\",");
                jsonString.Append("\"head_img\"" + ":\"" + dt.Rows[0]["head_img"].ToString() + "\",");
                jsonString.Append("\"awardcount\"" + ":\"\",");
                jsonString.Append("\"mymoney\"" + ":\"\",");
                jsonString.Append("\"mydo\"" + ":\"\",");
                jsonString.Append("\"mypoints\"" + ":\"\"");
                jsonString.Append("}");
            }
        }
        else
        {
            jsonString.Append("{\"result\":\"validateIdenError\"}");
        }
        context.Response.Write(jsonString.ToString());
        context.Response.End();
    }

    //获取注册验证码
    public void getValidateCode(HttpContext context)
    {
        string mobile = PageTool.GetAjaxParameter("mobile");
        string token = context.Request.Headers["x-ol-authtoken-ssl"];
        string openid = PageTool.GetAjaxParameter("Uid");
        StringBuilder jsonString = new StringBuilder();
        bool b = validateIden(context);
        if (b)
        {
            try
            {
                //短信服务器账号
                string sid = Core.GetConfig._xml_value("", "Base.config", "configuration/BaseConfigInfo/MessageID", "/wxapi/action");
                //短信服务器密码
                string spw = Core.GetConfig._xml_value("", "Base.config", "configuration/BaseConfigInfo/MessagePw", "/wxapi/action");
                //短信服务器地址
                string postUrl = Core.GetConfig._xml_value("", "Base.config", "configuration/BaseConfigInfo/MessageUrl", "/wxapi/action");
                //生成验证码
                string code = Core.RandomNum.Number(5);
                //消息内容
                string message = "验证码:" + code + "如非本人操作，请忽略本短信。该验证码将在1分钟后失效。【欧啦联盟】";
                string Postdate = "CorpID=" + sid + "&Pwd=" + spw + "&Mobile=" + mobile + "&Content=" + message;

                string sql = string.Format(@"insert into t_send_rcode 
                                        values(send_rcode_seq.nextval,'{0}','{1}',sysdate,'{2}','0','{3}','{4}')",
                                            mobile, message, code, token, openid);
                DbHelperWeb.ExecuteNonQuery(CommandType.Text, sql, null);

                //发送短信
                Core.Utils.PostSMS(postUrl, Postdate);
                jsonString.Append("{\"result\":\"true\"}");
            }
            catch (Exception e)
            {
                jsonString.Append("{\"result\":\"sendCodeError\"}");
                Utils.apiError(new DateTime() + "发送注册验证码错误:", e);
            }
        }
        else
        {
            jsonString.Append("{\"result\":\"validateIdenError\"}");
        }
        context.Response.Write(jsonString.ToString());
        context.Response.End();
    }

    //提交验证码
    public void getRegisterMobile(HttpContext context)
    {
        StringBuilder jsonString = new StringBuilder();
        bool b = validateIden(context);
        if (b)
        {
            try
            {
                string mobile = PageTool.GetAjaxParameter("mobile");
                string token = context.Request.Headers["x-ol-authtoken-ssl"];
                string openid = PageTool.GetAjaxParameter("Uid");
                string code = PageTool.GetAjaxParameter("code");
                string sql = string.Format(@"select * from t_send_rcode t where t.token='{0}' 
                                        and t.user_code='{1}' and t.rcode='{2}' and sysdate<t.create_time + 5/(24*60)",
                                           token, openid, code);
                DataTable dt = new DataTable();
                dt = DbHelperWeb.ExecuteTable(CommandType.Text, sql, null);
                if (dt.Rows.Count > 0)
                {
                    string sqlupdate = "update wx_user set link_phone='" + mobile + "' where open_id='" + openid + "'";
                    DbHelperWeb.ExecuteNonQuery(CommandType.Text, sqlupdate, null);
                    string mobileStr = mobile.Substring(0, 3) + "****" + mobile.Substring(7);
                    jsonString.Append("{\"result\":\"true\",\"resultMobile\":\"" + mobileStr + "\"}");
                }
            }
            catch (Exception e)
            {
                jsonString.Append("{\"result\":\"getRegisterMobileError\"}");
                Utils.apiError("提交手机验证错误:", e);
            }
        }
        else
        {
            jsonString.Append("{\"result\":\"validateIdenError\"}");
        }
        context.Response.Write(jsonString.ToString());
        context.Response.End();
    }
    
    //提交报单
    public void addProvideCustomer(HttpContext context)
    {
        StringBuilder jsonString = new StringBuilder();
        bool b = validateIden(context);
        if (b)
        {
            try
            {
                string openId = PageTool.GetAjaxParameter("Uid");
                string customerName = PageTool.GetAjaxParameter("name");
                string sex = PageTool.GetAjaxParameter("sex");
                string linkPhone = PageTool.GetAjaxParameter("telphone");
                string area = PageTool.GetAjaxParameter("city");
                string money = PageTool.GetAjaxParameter("needMoney");
                string job = PageTool.GetAjaxParameter("work");
                string loanType = PageTool.GetAjaxParameter("loanStyle");
                string description = PageTool.Mark_Parse(PageTool.GetAjaxParameter("sign"));

                int customerId = DbHelperWeb.getPkId("provide_customer_seq");
                string sqlInsert = string.Format(@"insert into wx_provide_customer values(" + customerId
                    + ",'{0}' ||  lpad(" + customerId + ", 7, '0'),'{1}','{2}','{3}',{4},'{5}','{6}','{7}',0,null,'{8}',sysdate,'{9}')",
                    "B" + Core.GetTime.DateNumber1().Substring(2), sex, linkPhone, area,
                    PageTool.StringToDecimal1(money), job, loanType, description, openId,customerName);
                DbHelperWeb.ExecuteNonQuery(CommandType.Text, sqlInsert, null);
                jsonString.Append("{\"result\":\"true\"}");

                string sqlCustomerCode = "select customer_code from wx_provide_customer where id=" + customerId;
                DataTable dt = DbHelperWeb.ExecuteTable(CommandType.Text, sqlCustomerCode, null);
                string customerCode = dt.Rows[0][0].ToString();

                //发送数据
                //StringBuilder postData = new StringBuilder();
                //postData.Append("{\"customerCode\":" + "\"" + customerCode + "\",");
                //postData.Append("\"accessTime\":" + "\"" + DateTime.Now.ToString() + "\",");
                //postData.Append("\"people\": [{");
                //postData.Append("\"CustomerCode\": \"customerCode\",");
                //postData.Append("\"Name\": \"" + customerName + "\",");
                //postData.Append("\"Phone\": \"" + linkPhone + "\",");
                //postData.Append("\"Sex\": \"" + sex + "\",");
                //postData.Append("\"City\": \"" + area + "\",");
                //postData.Append("\"NeedMoney\": \"" + money + "\",");
                //postData.Append("\"CreateTime\": \"" + DateTime.Now.ToString() + "\",");
                //postData.Append("\"Profession\": \"其它\",");
                //postData.Append("\"IP\": \"\",");
                //postData.Append("\"Income\": \"\",");
                //postData.Append("\"Birthday\": \"\"");
                //postData.Append("}]}");
                //string tagUrl = "";
                //HttpItem Cpitem = new HttpItem() { URL = tagUrl, IsToLower = false, Encoding = "utf-8", Postdata = postData.ToString() };
                //HttpGP http = new HttpGP();
                //string jsonStr = http.GetHtml(Cpitem);
            }
            catch (Exception e)
            {
                Utils.apiError("提交报单错误:", e);
                jsonString.Append("{\"result\":\"addProvideCustomerError\"}");
            }
        }
        else
        {
            jsonString.Append("{\"result\":\"validateIdenError\"}");
        }
        context.Response.Write(jsonString.ToString());
        context.Response.End();
    }
    
    //提交用户信息
    public void addUserExt(HttpContext context)
    {
        StringBuilder jsonString = new StringBuilder();
        bool b = validateIden(context);
        string sql = "";
        if (b)
        {
            try
            {
                string openId = PageTool.GetAjaxParameter("Uid");
                string identity = PageTool.GetAjaxParameter("idNumber");
                string name = PageTool.GetAjaxParameter("name");
                sql = "select * from wx_user_ext t where t.open_id='" + openId + "'";
                DataTable dt = new DataTable();
                dt = DbHelperWeb.ExecuteTable(CommandType.Text, sql, null);
                if (dt.Rows.Count > 0)
                {
                    sql = string.Format(@"update wx_user_ext t set t.identity='{0}',t.name='{1}' where t.open_id='{2}'",
                        identity, name, openId);
                }
                else
                {
                    sql = string.Format(@"insert into wx_user_ext values(wx_user_ext_seq.nextval,'{0}','{1}' ||  lpad(wx_user_ext_seq.nextval, 7, '0'),'{2}','{3}')",
                        openId, "C" + Core.GetTime.DateNumber1().Substring(2), identity, name);
                }
                DbHelperWeb.ExecuteNonQuery(CommandType.Text, sql, null);
                jsonString.Append("{\"result\":\"true\"}");
            }
            catch (Exception e)
            {
                Utils.apiError("完善个人资料错误:[" + sql + "]", e);
            }
        }
        else
        {
            jsonString.Append("{\"result\":\"validateIdenError\"}");
        }
        context.Response.Write(jsonString.ToString());
        context.Response.End();
    }
    
    //获取用户信息
    public void getUserExt(HttpContext context)
    {
        StringBuilder jsonString = new StringBuilder();
        bool b = validateIden(context);
        if (b)
        {
            string openid = PageTool.GetAjaxParameter("Uid");
            string sql = "select e.identity,e.user_code,e.name,t.link_phone,t.open_id,t.grade from wx_user t left join wx_user_ext e on e.open_id=t.open_id where t.open_id='" + openid + "'";
            DataTable dt = new DataTable();
            dt = DbHelperWeb.ExecuteTable(CommandType.Text, sql, null);
            if (dt.Rows.Count > 0)
            {
                jsonString.Append("{");
                jsonString.Append("\"result\":\"true\",");
                jsonString.Append("\"userInfo\":[");
                jsonString.Append("{");
                jsonString.Append("\"open_id\":" + "\"" + dt.Rows[0]["open_id"].ToString() + "\",");
                jsonString.Append("\"user_code\":" + "\"" + dt.Rows[0]["user_code"].ToString() + "\",");
                string phone = dt.Rows[0]["link_phone"].ToString();
                string phoneStr = "";
                if (!string.IsNullOrEmpty(phone))
                {
                    phoneStr = phone.Substring(0, 3) + "****" + phone.Substring(7);
                }
                jsonString.Append("\"link_phone\":" + "\"" + phoneStr + "\",");
                jsonString.Append("\"identity\":" + "\"" + dt.Rows[0]["identity"].ToString() + "\",");
                jsonString.Append("\"name\":" + "\"" + dt.Rows[0]["name"].ToString() + "\",");
                jsonString.Append("\"grade\":" + "\"" + dt.Rows[0]["grade"].ToString() + "\"");
                jsonString.Append("}");
                jsonString.Append("]}");
            }
        }
        else
        {
            jsonString.Append("{\"result\":\"validateIdenError\"}");
        }
        context.Response.Write(jsonString.ToString());
        context.Response.End();
    }
    
    public bool IsReusable {
        get {
            return false;
        }
    }

}