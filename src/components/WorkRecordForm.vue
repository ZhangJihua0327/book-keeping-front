<script setup>
import { ref, onMounted, reactive } from 'vue';
import axios from 'axios';

const API_BASE_URL = ''; // 使用 Vite 代理转发到 localhost:8000
// const API_BASE_URL = 'https://book-keeping-backend.lollipopzzz.cn';

// Data models
const customers = ref([]);
const trunkModels = ref([]);
const todaysRecords = ref([]); // Records for the day

// Form State
const form = reactive({
  date: (() => {
    const now = new Date();
    return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
  })(),
  customer_name: '',
  trunk_model: '',
  construction_site: '',
  quantity: 0,
  price: 0,
  charged: false,
  remark: ''
});

// Loading/Error states
const loading = ref(false);
const error = ref(null);
const success = ref(false);

// Add New State
const newCustomerName = ref('');
const showAddCustomer = ref(false);
const newTrunkModelName = ref('');
const showAddTrunkModel = ref(false);

// Edit State
const showEditModal = ref(false);
const editingForm = reactive({
  record_id: '',
  date: '',
  customer_name: '',
  trunk_model: '',
  construction_site: '',
  quantity: 0,
  price: 0,
  charged: false,
  remark: ''
});

// API Client
const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json'
  }
});

// Lifecycle
onMounted(async () => {
  await fetchData();
  await fetchTodaysRecords();
});

const fetchData = async () => {
  try {
    const [custRes, modelRes] = await Promise.all([
      api.get('/api/customers'),
      api.get('/api/models')
    ]);
    customers.value = custRes.data;
    trunkModels.value = modelRes.data;
  } catch (err) {
    console.error('Failed to load data', err);
    error.value = '无法加载选项数据 (' + API_BASE_URL + ').';
  }
};

const fetchTodaysRecords = async () => {
  try {
    // 使用本地时间获取当前日期 YYYY-MM-DD
    const now = new Date();
    const todayStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
    
    // 直接调用后端接口筛选日期
    const res = await api.get('/api/records', { params: { date: todayStr } });

    if (res.data && Array.isArray(res.data)) {
        todaysRecords.value = res.data;
    }
  } catch (err) {
    console.error('Failed to load today\'s records', err);
  }
};

// Actions
const submitForm = async () => {
  loading.value = true;
  error.value = null;
  success.value = false;
  
  try {
    // Validate
    if (!form.customer_name || !form.trunk_model) {
      throw new Error('请选择客户和车型');
    }

    const payload = { ...form };
    // Ensure numbers
    payload.quantity = parseInt(payload.quantity);
    payload.price = parseInt(payload.price);

    await api.post('/api/records', payload);
    success.value = true;
    
    // Clear numeric fields but keep date, site maybe?
    form.quantity = 0;
    form.price = 0;
    form.remark = '';

    // Refresh today's records
    await fetchTodaysRecords();

  } catch (err) {
    console.error('Submit error', err);
    // Determine error message
    const msg = err.response?.data?.error || err.message || '提交失败';
    error.value = msg;
  } finally {
    loading.value = false;
  }
};

const addCustomer = async () => {
  if (!newCustomerName.value) return;
  try {
    await api.post('/api/customers', { customer_name: newCustomerName.value });
    await fetchData(); // Refresh list
    form.customer_name = newCustomerName.value; // Auto select
    newCustomerName.value = '';
    showAddCustomer.value = false;
  } catch (err) {
    alert('无法添加客户: ' + (err.response?.data?.error || err.message));
  }
};

const addTrunkModel = async () => {
  if (!newTrunkModelName.value) return;
  try {
    await api.post('/api/models', { trunk_model: newTrunkModelName.value });
    await fetchData(); // Refresh list
    form.trunk_model = newTrunkModelName.value; // Auto select
    newTrunkModelName.value = '';
    showAddTrunkModel.value = false;
  } catch (err) {
    alert('无法添加车型: ' + (err.response?.data?.error || err.message));
  }
};

const deleteRecord = async (record) => {
  if (!confirm(`确定要删除这条记录吗?\n${record.customer_name} - ${record.trunk_model}`)) return;
  
  try {
    await api.delete(`/api/records/${record.record_id}`);
    await fetchTodaysRecords();
  } catch (err) {
    alert('删除失败: ' + (err.response?.data?.error || err.message));
  }
};

const openEditModal = (record) => {
  // Copy data to editing form
  Object.assign(editingForm, record);
  // Ensure date is YYYY-MM-DD
  if (editingForm.date && typeof editingForm.date === 'string' && editingForm.date.includes('T')) {
    editingForm.date = editingForm.date.split('T')[0];
  }
  showEditModal.value = true;
};

const closeEditModal = () => {
  showEditModal.value = false;
};

const updateRecord = async () => {
  try {
    const payload = { ...editingForm };
    payload.quantity = parseInt(payload.quantity);
    payload.price = parseInt(payload.price);
    
    await api.put(`/api/records/${payload.record_id}`, payload);
    await fetchTodaysRecords();
    closeEditModal();
  } catch (err) {
    alert('更新失败: ' + (err.response?.data?.error || err.message));
  }
};
</script>

<template>
  <div class="form-wrapper">
    <div v-if="error" class="error-msg">{{ error }}</div>
    <div v-if="success" class="success-msg">记录已保存!</div>

    <form @submit.prevent="submitForm">
      
      <!-- Date -->
      <div class="form-group">
        <label>日期</label>
        <input type="date" v-model="form.date" required />
      </div>

      <!-- Customer -->
      <div class="form-group">
        <label>客户</label>
        <div class="select-wrapper">
          <select v-model="form.customer_name" required>
            <option disabled value="">-- 请选择客户 --</option>
            <option v-for="c in customers" :key="c.id" :value="c.customer_name">{{ c.customer_name }}</option>
          </select>
          <button type="button" @click="showAddCustomer = !showAddCustomer" class="add-btn-icon" title="添加新客户">+</button>
        </div>
        
        <div v-if="showAddCustomer" class="add-box">
          <input v-model="newCustomerName" placeholder="输入新客户名" />
          <button type="button" @click="addCustomer" class="save-small-btn">保存</button>
        </div>
      </div>

      <!-- Trunk Model -->
      <div class="form-group">
        <label>车型</label>
        <div class="select-wrapper">
          <select v-model="form.trunk_model" required>
            <option disabled value="">-- 请选择车型 --</option>
            <option v-for="m in trunkModels" :key="m.id" :value="m.trunk_model">{{ m.trunk_model }}</option>
          </select>
          <button type="button" @click="showAddTrunkModel = !showAddTrunkModel" class="add-btn-icon" title="添加新车型">+</button>
        </div>

        <div v-if="showAddTrunkModel" class="add-box">
          <input v-model="newTrunkModelName" placeholder="输入新车型" />
          <button type="button" @click="addTrunkModel" class="save-small-btn">保存</button>
        </div>
      </div>

      <!-- Construction Site -->
      <div class="form-group">
        <label>施工地点</label>
        <input type="text" v-model="form.construction_site" required placeholder="请输入地址" />
      </div>

      <!-- Quantity & Price -->
      <div class="row">
        <div class="form-group half">
          <label>方量</label>
          <input type="number" v-model.number="form.quantity" required min="1" placeholder="0" />
        </div>
        <div class="form-group half">
          <label>价格</label>
          <input type="number" v-model.number="form.price" required min="0" placeholder="¥ 0" />
        </div>
      </div>

      <!-- Charged -->
      <div class="form-group checkbox-group">
        <label>
          <input type="checkbox" v-model="form.charged" />
          是否已经收费
        </label>
      </div>

      <!-- Remark -->
      <div class="form-group">
        <label>备注</label>
        <textarea v-model="form.remark" placeholder="备注信息 (可选)"></textarea>
      </div>

      <button type="submit" :disabled="loading" class="submit-btn">
        {{ loading ? '提交中...' : '创建记录' }}
      </button>
    </form>

    <div class="records-section">
      <h3>今日登记记录</h3>
      <div class="table-container" v-if="todaysRecords.length > 0">
        <table>
          <thead>
            <tr>
              <th>客户</th>
              <th>车型</th>
              <th>地点</th>
              <th>方量</th>
              <th>价格</th>
              <th>收费</th>
              <th>操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="record in todaysRecords" :key="record.record_id">
              <td>{{ record.customer_name }}</td>
              <td>{{ record.trunk_model }}</td>
              <td>{{ record.construction_site }}</td>
              <td>{{ record.quantity }}</td>
              <td>{{ record.price }}</td>
              <td>
                <span :class="['tag', record.charged ? 'tag-yes' : 'tag-no']">
                  {{ record.charged ? '是' : '否' }}
                </span>
              </td>
              <td class="action-buttons">
                <button @click="openEditModal(record)" class="edit-btn">修改</button>
                <button @click="deleteRecord(record)" class="delete-btn">删除</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <div v-else class="empty-hint">
        今天还没有创建记录
      </div>
    </div>

    <!-- Edit Modal -->
    <div v-if="showEditModal" class="modal-overlay">
      <div class="modal-content">
        <h3>修改记录</h3>
        <form @submit.prevent="updateRecord">
           <!-- Date -->
          <div class="form-group">
            <label>日期</label>
            <input type="date" v-model="editingForm.date" required />
          </div>

          <!-- Customer -->
          <div class="form-group">
            <label>客户</label>
            <select v-model="editingForm.customer_name" required>
              <option disabled value="">-- 请选择客户 --</option>
              <option v-for="c in customers" :key="c.id" :value="c.customer_name">{{ c.customer_name }}</option>
            </select>
          </div>

          <!-- Trunk Model -->
          <div class="form-group">
            <label>车型</label>
            <select v-model="editingForm.trunk_model" required>
              <option disabled value="">-- 请选择车型 --</option>
              <option v-for="m in trunkModels" :key="m.id" :value="m.trunk_model">{{ m.trunk_model }}</option>
            </select>
          </div>

          <!-- Construction Site -->
          <div class="form-group">
            <label>施工地点</label>
            <input type="text" v-model="editingForm.construction_site" required placeholder="请输入地址" />
          </div>

          <!-- Quantity & Price -->
          <div class="row">
            <div class="form-group half">
              <label>方量</label>
              <input type="number" v-model.number="editingForm.quantity" required min="1" />
            </div>
            <div class="form-group half">
              <label>价格</label>
              <input type="number" v-model.number="editingForm.price" required min="0" />
            </div>
          </div>

          <!-- Charged -->
          <div class="form-group checkbox-group">
            <label>
              <input type="checkbox" v-model="editingForm.charged" />
              是否已经收费
            </label>
          </div>

          <!-- Remark -->
          <div class="form-group">
            <label>备注</label>
            <textarea v-model="editingForm.remark" placeholder="备注信息 (可选)"></textarea>
          </div>

          <div class="modal-actions">
            <button type="button" @click="closeEditModal" class="cancel-btn">取消</button>
            <button type="submit" class="save-btn">保存修改</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<style scoped>
.form-wrapper {
  background: #ffffff;
  padding: 2rem;
  border-radius: 8px;
  text-align: left;
  max-width: 600px;
  margin: 0 auto;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
  border: 1px solid #eee;
}
.form-group {
  margin-bottom: 1.5rem;
}
label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: bold;
  color: #333;
}
input[type="text"],
input[type="date"],
input[type="number"],
select,
textarea {
  width: 100%;
  padding: 10px;
  border: 1px solid #ddd;
  background: #fff;
  color: #333;
  border-radius: 4px;
  box-sizing: border-box;
  transition: border-color 0.2s;
}
input:focus,
select:focus,
textarea:focus {
  outline: none;
  border-color: #646cff;
}
select {
  cursor: pointer;
}
textarea {
  min-height: 80px;
}

/* Select wrapper for the + button */
.select-wrapper {
  display: flex;
  gap: 10px;
}
.add-btn-icon {
  background: #f0f0f0;
  border: 1px solid #ddd;
  color: #666;
  width: 40px;
  font-size: 1.2rem;
  cursor: pointer;
  border-radius: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.2s;
}
.add-btn-icon:hover {
  background: #e0e0e0;
}

.add-box {
  margin-top: 10px;
  display: flex;
  gap: 5px;
  background: #f9f9f9;
  padding: 10px;
  border-radius: 4px;
  border: 1px dashed #ccc;
}
.save-small-btn {
  background: #42b983;
  border: none;
  color: white;
  padding: 0 15px;
  border-radius: 4px;
  cursor: pointer;
  white-space: nowrap;
}
.save-small-btn:hover {
  background: #3aa876;
}

.submit-btn {
  width: 100%;
  padding: 12px;
  background: #646cff; /* Vite blue */
  color: white;
  border: none;
  border-radius: 4px;
  font-size: 1.1rem;
  font-weight: bold;
  cursor: pointer;
  transition: background 0.2s;
  margin-bottom: 2rem;
}
.submit-btn:hover {
  background: #535bf2;
}
.submit-btn:disabled {
  background: #ccc;
  cursor: not-allowed;
}
.error-msg {
  color: #d32f2f;
  margin-bottom: 1rem;
  padding: 10px;
  background: #ffebee;
  border-left: 4px solid #d32f2f;
}
.success-msg {
  color: #388e3c;
  margin-bottom: 1rem;
  padding: 10px;
  background: #e8f5e9;
  border-left: 4px solid #388e3c;
}
.row {
  display: flex;
  gap: 1rem;
}

.action-buttons {
  display: flex;
  gap: 5px;
}
.edit-btn, .delete-btn {
  padding: 4px 8px;
  font-size: 0.8rem;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  color: white;
}
.edit-btn {
  background: #2196F3;
}
.edit-btn:hover {
  background: #1976D2;
}
.delete-btn {
  background: #f44336;
}
.delete-btn:hover {
  background: #d32f2f;
}

/* Modal Styles */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}
.modal-content {
  background: white;
  padding: 2rem;
  border-radius: 8px;
  width: 90%;
  max-width: 500px;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
}
.modal-content h3 {
  margin-top: 0;
  margin-bottom: 1.5rem;
  text-align: center;
  color: #333;
}
.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  margin-top: 2rem;
}
.cancel-btn, .save-btn {
  padding: 8px 16px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-weight: bold;
}
.cancel-btn {
  background: #eee;
  color: #333;
}
.cancel-btn:hover {
  background: #e0e0e0;
}
.save-btn {
  background: #646cff; /* Vite blue */
  color: white;
}
.save-btn:hover {
  background: #535bf2;
}
.half {
  flex: 1;
}
.checkbox-group label {
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
  font-weight: normal;
}
.empty-hint {
  color: #999;
  font-style: italic;
  font-size: 0.9em;
  padding: 10px;
  text-align: center;
}

/* Records Section */
.records-section {
  border-top: 1px solid #ddd;
  padding-top: 1rem;
}
.records-section h3 {
  color: #333;
  margin-bottom: 1rem;
  font-size: 1.1rem;
}
.table-container {
  overflow-x: auto;
}
table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.9rem;
}
th, td {
  text-align: left;
  padding: 8px;
  border-bottom: 1px solid #eee;
  color: #333;
}
th {
  color: #666;
  font-weight: 600;
  background: #f5f5f5;
}
tr:last-child td {
  border-bottom: none;
}
tr:hover td {
  background-color: #fcfcfc;
}
.tag {
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 0.8rem;
  font-weight: bold;
}
.tag-yes {
  background: #e8f5e9;
  color: #2e7d32;
  border: 1px solid #c8e6c9;
}
.tag-no {
  background: #ffebee;
  color: #c62828;
  border: 1px solid #ffcdd2;
}
</style>
