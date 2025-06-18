import { render, screen } from '@testing-library/react';
import App from './App';

const x = [1,2,3]
const y = x.filter(x => x < 2)

test('renders welcome message', () => {
  render(<App />);
  const linkElement = screen.getByText(/Hello, DevOps Engineer!/i);
  expect(linkElement).toBeInTheDocument();
});
