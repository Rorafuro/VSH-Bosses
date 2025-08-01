static int g_iClientTaggedIndex;

public void Tag_Create(SaxtonHaleBase boss)
{
	boss.SetPropInt("Tag", "MaxHeal", 1000);
}

public void Tag_OnPlayerKilled(SaxtonHaleBase boss, Event event, int iVictim)
{
  // Was our Client Index our TAG index?

}

public void Tag_OnThink(SaxtonHaleBase boss)
{
  
}