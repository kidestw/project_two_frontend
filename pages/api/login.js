import withSession from '@/lib/session'
import axios from 'axios'

export default withSession(async (req, res) => {
    if (req.method !== 'POST') {
        return res.status(405).json({ message: 'Method Not Allowed' });
    }

    const { username, password } = req.body;
    const loginUrl = `${process.env.BACKEND_API_HOST}/api/login`;

    try {
        const response = await axios.post(loginUrl, {
            username,
            password
        }, {
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'X-Requested-With': 'XMLHttpRequest',
            },
            withCredentials: true,
        });

        if (response.status === 200) {
            const { user, api_token } = response.data;

            req.session.set('user', user);
            req.session.set('api_token', api_token);
            await req.session.save();

            return res.status(200).json({ logged_in: true });
        }

        return res.status(response.status).json({
            logged_in: false,
            message: response.data.message || 'Login failed',
            errors: response.data.errors || null
        });

    } catch (err) {
        console.error('Login error:', err?.response?.data || err.message);
        return res.status(500).json({
            logged_in: false,
            message: err?.response?.data?.message || 'Server error',
            errors: err?.response?.data?.errors || null
        });
    }
});
