#include <iostream>

#include "plant.hh"

Plant::Plant (std::string name)
{
    if (name.empty()) {
        name = "unknown";
    }
    else {
        m_name = name;
    }
}

void Plant::talk () const
{
    using namespace std;

    cout << m_name << " has \"" << m_leaves << "\" leaves" << endl;
}
