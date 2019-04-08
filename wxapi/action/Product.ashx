<%@ WebHandler Language="C#" Class="Product" %>

using System;
using System.Web;
using System.Data;
using System.Data.Common;
using OrclData;
using System.Data.OracleClient;
using System.Text;
using Core;

public class Product : IHttpHandler {
    
    public void ProcessRequest (HttpContext context) {
        SQLMos s = new SQLMos();
        string type = context.Request.Params["Judgem"];
        switch (type)
        {
            case "getProductList": //获取产品列表
                getProductList(context);
                break;
            case "getProductType"://获取产品类型
                getProductType(context);
                break;
            case "productDetail"://产品详情
                productDetail(context);
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

    //获取产品列表
    public void getProductList(HttpContext context)
    {
        StringBuilder jsonString = new StringBuilder();
        bool b = validateIden(context);
        if (b)
        {
            try
            {
                int pageSize = int.Parse(PageTool.GetAjaxParameter("pageSize"));
                string pageIndex = PageTool.GetAjaxParameter("pageIndex");
                int endpage = (int.Parse(pageIndex) - 1) * pageSize;
                int spageRow = pageSize * int.Parse(pageIndex);
                string type = PageTool.GetAjaxParameter("type");
                string sql = string.Format(@"select * from ( select A.*, rownum rn from (
                                        select t.id,t.product_name,t.abbreviation,t.title,t.keyword,t.profit,
                                        t.create_time,t.profit_type
                                        from t_product t 
                                        where t.isreleasewx=1 and t.product_type={0} order by t.create_time desc
                                        )a 
                                    where rownum <= {1} order by create_time desc) where rn > {2} order by create_time desc ",
                                        PageTool.Int32_Parse1(type), spageRow, endpage);
                string csql = string.Format(@"select count(*) from t_product t where t.isreleasewx=1 and t.product_type={0} ", PageTool.Int32_Parse1(type));
                DataTable dt = new DataTable();
                dt = DbHelperWeb.ExecuteTable(CommandType.Text, sql, null);
                string total = Core.Sql.ShowList.ReturnCount(csql);
                if (dt.Rows.Count > 0)
                {
                    jsonString.Append("{");
                    jsonString.Append("\"result\":\"true\",\"totalCount\":\"" + total + "\",");
                    jsonString.Append("\"products\":[");
                    for (int i = 0; i < dt.Rows.Count; i++)
                    {
                        if (i != dt.Rows.Count - 1)
                        {
                            jsonString.Append("{");
                            jsonString.Append("\"id\":" + "\"" + dt.Rows[i]["id"].ToString() + "\",");
                            jsonString.Append("\"product_name\":" + "\"" + dt.Rows[i]["product_name"].ToString() + "\",");
                            jsonString.Append("\"abbreviation\":" + "\"" + dt.Rows[i]["abbreviation"].ToString() + "\",");
                            jsonString.Append("\"title\":" + "\"" + dt.Rows[i]["title"].ToString() + "\",");
                            jsonString.Append("\"keyword\":" + "\"" + dt.Rows[i]["keyword"].ToString() + "\",");
                            jsonString.Append("\"profit\":" + "\"" + dt.Rows[i]["profit"].ToString() + "\",");
							jsonString.Append("\"profit_type\":" + "\"" + dt.Rows[i]["profit_type"].ToString() + "\"");
                            jsonString.Append("},");
                        }
                        else
                        {
                            jsonString.Append("{");
                            jsonString.Append("\"id\":" + "\"" + dt.Rows[i]["id"].ToString() + "\",");
                            jsonString.Append("\"product_name\":" + "\"" + dt.Rows[i]["product_name"].ToString() + "\",");
                            jsonString.Append("\"abbreviation\":" + "\"" + dt.Rows[i]["abbreviation"].ToString() + "\",");
                            jsonString.Append("\"title\":" + "\"" + dt.Rows[i]["title"].ToString() + "\",");
                            jsonString.Append("\"keyword\":" + "\"" + dt.Rows[i]["keyword"].ToString() + "\",");
                            jsonString.Append("\"profit\":" + "\"" + dt.Rows[i]["profit"].ToString() + "\",");
							jsonString.Append("\"profit_type\":" + "\"" + dt.Rows[i]["profit_type"].ToString() + "\"");
                            jsonString.Append("}");
                        }
                    }
                    jsonString.Append("]}");
                }
            }
            catch (Exception ex)
            {
                Core.Utils.apiError(ex.ToString(), new Exception());
            }
        }
        else
        {
            jsonString.Append("{\"result\":\"validateIdenError\"}");
        }
        context.Response.Write(jsonString.ToString());
        context.Response.End();
    }

    //获取产品类型
    public void getProductType(HttpContext context)
    {
        StringBuilder jsonString = new StringBuilder();
        bool b = validateIden(context);
        if (b)
        {
            string sql = "select t.id,t.name from t_product_type t";
            DataTable dt = new DataTable();
            dt = DbHelperWeb.ExecuteTable(CommandType.Text, sql, null);
            if (dt.Rows.Count > 0)
            {
                jsonString.Append("{");
                jsonString.Append("\"result\":\"true\",");
                jsonString.Append("\"productTypes\":[");
                for (int i = 0; i < dt.Rows.Count; i++)
                {
                    if (i != dt.Rows.Count - 1)
                    {
                        jsonString.Append("{");
                        jsonString.Append("\"id\":" + "\"" + dt.Rows[i]["id"].ToString() + "\",");
                        jsonString.Append("\"name\":" + "\"" + dt.Rows[i]["name"].ToString() + "\"");
                        jsonString.Append("},");
                    }
                    else
                    {
                        jsonString.Append("{");
                        jsonString.Append("\"id\":" + "\"" + dt.Rows[i]["id"].ToString() + "\",");
                        jsonString.Append("\"name\":" + "\"" + dt.Rows[i]["name"].ToString() + "\"");
                        jsonString.Append("}");
                    }
                }
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
    
    //产品详情
    public void productDetail(HttpContext context)
    {
        StringBuilder jsonString = new StringBuilder();
        string productId = PageTool.GetAjaxParameter("id");
        bool b = validateIden(context);
        if (b)
        {
            string sql = string.Format(@"select t.id,t.product_code,t.product_name,t.abbreviation,t.create_time,t.description,t.readnum,t.keyword,
                                        (select wm_concat(i.product_img) from t_product_img i where i.product_id=t.id) as productImg,
										t.profit_type,t.profit										
                                        from t_product t 
                                        left join t_product_img i on i.product_id=t.id where t.id={0}",
                                        PageTool.Int32_Parse1(productId));
            DataTable dt = new DataTable();
			dt = DbHelperWeb.ExecuteTable(CommandType.Text, sql, null);
            if (dt.Rows.Count > 0)
            {
                jsonString.Append("{");
                jsonString.Append("\"result\":\"true\",");
                jsonString.Append("\"productDetail\":[");
                jsonString.Append("{");
                jsonString.Append("\"id\":" + "\"" + dt.Rows[0]["id"].ToString() + "\",");
                jsonString.Append("\"product_code\":" + "\"" + dt.Rows[0]["product_code"].ToString() + "\",");
                jsonString.Append("\"product_name\":" + "\"" + dt.Rows[0]["product_name"].ToString() + "\",");
                jsonString.Append("\"abbreviation\":" + "\"" + dt.Rows[0]["abbreviation"].ToString() + "\",");
                jsonString.Append("\"create_time\":" + "\"" + PageTool.ToDateTime(dt.Rows[0]["create_time"].ToString()) + "\",");
                jsonString.Append("\"description\":" + "\"" + dt.Rows[0]["description"].ToString() + "\",");
                jsonString.Append("\"productImg\":" + "\"" + dt.Rows[0]["productImg"].ToString() + "\",");
                jsonString.Append("\"readnum\":" + "\"" + dt.Rows[0]["readnum"].ToString() + "\",");
                jsonString.Append("\"keyword\":" + "\"" + dt.Rows[0]["keyword"].ToString() + "\",");
				jsonString.Append("\"profit\":" + "\"" + dt.Rows[0]["profit"].ToString() + "\",");
                jsonString.Append("\"profit_type\":" + "\"" + dt.Rows[0]["profit_type"].ToString() + "\"");
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