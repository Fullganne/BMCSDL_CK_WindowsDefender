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
    public partial class frmQuanLyNhanVien : Form
    {
        private dbContext db;
        private string username, password;
        private SqlConnection conn;
        public frmQuanLyNhanVien(string username, string password)
        {
            InitializeComponent();
            db = new dbContext();
            this.username = username;
            this.password = password;
            db.SetConnectionString(username, password);
            conn = db.GetConnection();
        }


        private void btnCancel_Click(object sender, EventArgs e)
        {

        }

        private void btnSave_Click(object sender, EventArgs e)
        {

        }

        private void btnDelete_Click(object sender, EventArgs e)
        {

        }

        private void btnUpdate_Click(object sender, EventArgs e)
        {

        }

        private void btnAdd_Click(object sender, EventArgs e)
        {

        }

        private void txtSearch_TextChanged(object sender, EventArgs e)
        {

        }

        private void btnClose_Click(object sender, EventArgs e)
        {
            this.Close();
        }

        private void btnRefresh_Click(object sender, EventArgs e)
        {
            LoadListEmployee();
        }

        private void btnBack_Click(object sender, EventArgs e)
        {

        }

        private void btnSearch_Click_1(object sender, EventArgs e)
        {

        }

        private void frmQuanLyNhanVien_Load(object sender, EventArgs e)
        {
            LoadListEmployee();

        }

        private void LoadListEmployee()
        {
            conn.Open();

            // Mở symmetric key
            SqlCommand openKeyCmd = new SqlCommand("OPEN SYMMETRIC KEY SalaryKey DECRYPTION BY CERTIFICATE SalaryCert;", conn);
            openKeyCmd.ExecuteNonQuery();

            // Truy vấn view
            SqlCommand cmd = new SqlCommand("SELECT * FROM QuanLyNhanVien", conn);
            SqlDataAdapter adapter = new SqlDataAdapter(cmd);
            DataTable dt = new DataTable();
            adapter.Fill(dt);

            // Đóng symmetric key
            SqlCommand closeKeyCmd = new SqlCommand("CLOSE SYMMETRIC KEY SalaryKey;", conn);
            closeKeyCmd.ExecuteNonQuery();

            // Bind data to DataGridView
            dgvListEmployee.DataSource = dt;
        }
    }
}
