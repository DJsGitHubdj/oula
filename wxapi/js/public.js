
//封装url信息截取函数
function GetQueryString(name) {
    var LocString = String(window.document.location.href);
    var rs = new RegExp("(^|)" + name + "=([^&]*)(&|$)", "gi").exec(LocString), tmp;
    if (tmp = rs) return tmp[2];
    return null;
}
//base64转码函数
function base64ToUtf_8(str) {
    return decodeURIComponent(escape(atob(str)));
}
//获取cookie
function getCookie(c_name) {
    if (document.cookie.length > 0) {
        c_start = document.cookie.indexOf(c_name + "=")
        if (c_start != -1) {
            c_start = c_start + c_name.length + 1
            c_end = document.cookie.indexOf(";", c_start)
            if (c_end == -1) c_end = document.cookie.length
            return unescape(document.cookie.substring(c_start, c_end))
        }
    }
    return "";
}
var userInfo = base64ToUtf_8(getCookie('userInfo'));
var SafeCode = "";
var Uid = "";
var Tim = "";
var tiket = "";
var appId = "";
var purl = location.href.split('#')[0];

if (userInfo != "") {
    var userInfoArr = userInfo.split("$");
    SafeCode = userInfoArr[0];
    Uid = userInfoArr[1];
    Tim = userInfoArr[2];
    tiket = userInfoArr[3];
    appId = userInfoArr[4];
}

function configValidate() {
    mui.ajax('action/User.ashx', {
        data: {
            "Judgem": "configValidate",
            "tiket": tiket,
            "purl": purl,
            "openid": Uid,
            "time": Tim
        },
        beforeSend: function (request) {
            request.setRequestHeader("x-ol-authtoken-ssl", SafeCode);
        },
        dataType: 'text',//服务器返回json格式数据
        type: 'post',//HTTP请求类型
        success: function (data) {
            var jsonData = JSON.parse(data);
            if (jsonData.result == "true") {
                wx.config({
                    debug: false, //
                    appId: jsonData.appId, // 必填，公众号的唯一标识
                    timestamp: jsonData.timestamp, // 必填，生成签名的时间戳
                    nonceStr: jsonData.nonceStr, // 必填，生成签名的随机串
                    signature: jsonData.signature, // 必填，签名，见附录1
                    jsApiList: ['hideAllNonBaseMenuItem', 'updateAppMessageShareData'] // 必填，需要使用的JS接口列表，所有JS接口列表见附录2
                });
                wx.ready(function () {
                    wx.hideAllNonBaseMenuItem();
                });
            } else {
                mui.openWindow({
                    url: '404.html',
                    id: '404'
                })
            }
        },
        error: function (xhr, type, errorThrown) {
            mui.openWindow({
                url: '404.html',
                id: '404'
            })
        }
    });
}

mui.ready(function () {
    mui('.mui-bar-tab').on('tap', 'a', function () {
        location.href = this.getAttribute('href');
    })
})