using QuanLyNhanVien;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Data.SqlClient;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace BMCSDL_CK_WindowsDefender
{
    public partial class frmDangNhap : Form
    {
        private dbContext db;

        public frmDangNhap()
        {
            InitializeComponent();
            db = new dbContext(); // Tạo đối tượng dbContext
        }

        private void btnLogin_Click(object sender, EventArgs e)
        {
            label4.Visible = false;

            if (!string.IsNullOrEmpty(txtUsername.Text) && !string.IsNullOrEmpty(txtPassword.Text))
            {
                db.SetConnectionString(txtUsername.Text, txtPassword.Text);

                try
                {
                    SqlConnection conn = db.GetConnection();
                    conn.Open();

                    if (db.IsConnectionOpen())
                    {
                        // Kết nối thành công, mở form quản lý nhân viên
                        frmQuanLyNhanVien frmQuanLyNhanVien = new frmQuanLyNhanVien(txtUsername.Text, txtPassword.Text);
                        frmQuanLyNhanVien.FormClosed += (s, args) => this.Show();
                        frmQuanLyNhanVien.Show();
                        this.Hide(); // Ẩn form đăng nhập
                    }
                    else
                    {
                        // Kết nối thất bại, hiển thị thông báo lỗi
                        label4.Text = "Tài khoản/mật khẩu không đúng!";
                        label4.Visible = true;
                    }
                }
                catch (Exception ex)
                {
                    // Xử lý lỗi kết nối
                    label4.Text = "Lỗi kết nối: " + ex.Message;
                    label4.Visible = true;
                }
                finally
                {
                    db.CloseConnection();
                }
            }
            else
            {
                label4.Text = "Vui lòng nhập tài khoản/mật khẩu!";
                label4.Visible = true;
            }
        }
    }
}
