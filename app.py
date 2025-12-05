import sqlite3
from flask import Flask, render_template, request, redirect, session, url_for

app = Flask(__name__)
app.secret_key = 'SUPER_SECRET_KEY_CHANGE_THIS'  # Поменяй на что-то сложное
ADMIN_PASSWORD = 'gl1ch'  # Твой пароль для входа

# --- База Данных ---
def init_db():
    conn = sqlite3.connect('projects.db')
    c = conn.cursor()
    # Создаем таблицу, если её нет
    c.execute('''CREATE TABLE IF NOT EXISTS projects 
                 (id INTEGER PRIMARY KEY, title TEXT, desc TEXT, link TEXT)''')
    conn.commit()
    conn.close()

# --- Главная страница ---
@app.route('/')
def home():
    conn = sqlite3.connect('projects.db')
    c = conn.cursor()
    c.execute("SELECT * FROM projects ORDER BY id DESC")
    projects = c.fetchall()
    conn.close()
    return render_template('index.html', projects=projects)

# --- Логин (Обработчик скрытой кнопки) ---
@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        if request.form['password'] == ADMIN_PASSWORD:
            session['logged_in'] = True
            return redirect(url_for('admin'))
        else:
            return "Неверный пароль!"
    return render_template('login.html') # Мы используем модальное окно, но это резерв

# --- Админка ---
@app.route('/admin', methods=['GET', 'POST'])
def admin():
    if not session.get('logged_in'):
        return redirect(url_for('home'))

    if request.method == 'POST':
        # Добавление проекта
        title = request.form['title']
        desc = request.form['desc']
        link = request.form['link']
        
        conn = sqlite3.connect('projects.db')
        c = conn.cursor()
        c.execute("INSERT INTO projects (title, desc, link) VALUES (?, ?, ?)", (title, desc, link))
        conn.commit()
        conn.close()
        return redirect(url_for('home')) # После добавления кидает на главную

    return render_template('admin.html')

# --- Выход ---
@app.route('/logout')
def logout():
    session.pop('logged_in', None)
    return redirect(url_for('home'))

if __name__ == '__main__':
    init_db()
    # Запускаем на всех интерфейсах (0.0.0.0), чтобы было видно через IP
    app.run(host='0.0.0.0', port=80, debug=True)
