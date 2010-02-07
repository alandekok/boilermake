#include <cat.hh>
#include <chihuahua.hh>
#include <mouse.hh>
#include <tree.hh>

int main (int argc, char * argv [])
{
    Cat lili("Lili");
    Dog rolf("Rolf");
    Chihuahua gidget("Gidget");
    Mouse mickey("Mickey");
    Tree tree("Larch");

    lili.talk();
    rolf.talk();
    gidget.talk();
    mickey.talk();
    tree.talk();

    return 0;
}
